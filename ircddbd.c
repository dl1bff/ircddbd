/*

ircddbd daemon

Copyright (C) 2011   Michael Dirska, DL1BFF (dl1bff@mdx.de)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/


#include <sys/types.h>
#include <sys/wait.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <syslog.h>
#include <errno.h>
#include <fcntl.h>

#include <unistd.h>
#include <signal.h>

#include "libutil.h"

#include "ircddbd_version.h"

#if !defined(IRCDDBD_VERSION)
#define IRCDDBD_VERSION "debug-version"
#endif


#define SYSLOG_PROGRAM_NAME "ircddbd"


static void usage(const char * a)
{
  fprintf (stderr, SYSLOG_PROGRAM_NAME " version '%s'\n"
    "Usage: %s <pid-file> <working dir> <stdout file> <stderr file>\n", IRCDDBD_VERSION, a);
}

int pid;
int end_flag;

void sig_handler ( int signum )
{
  syslog(LOG_INFO, "signal %d received", signum);

  if (pid != 0)
  {
    kill( pid, signum );
    syslog(LOG_INFO, "signal %d sent to pid %d", signum, pid);
  }

  end_flag = 1;
}



int main(int argc, char *argv[])
{

  if ((argc != 5))
  {
    usage(argv[0]);
    return 1;
  }

  openlog (SYSLOG_PROGRAM_NAME, LOG_PID, LOG_DAEMON);

  pid = 0;
  end_flag = 0;

  struct sigaction sa;

  sigemptyset( & sa.sa_mask );
  sa.sa_flags = 0;
  sa.sa_handler = sig_handler;

  int r;

  r = sigaction ( SIGTERM, &sa, 0);

  if (r < 0)
  {
    perror("sigaction failed");
    return 1;
  }

  const char * pidfile_name = NULL;

  pidfile_name = argv[1];

  struct pidfh * pfh = NULL;

  if (pidfile_name != NULL)
  {
    pid_t otherpid;

    pfh = pidfile_open(pidfile_name, 0600, &otherpid);

    if (pfh == NULL)
    {
      if (errno == EEXIST)
      {
        fprintf(stderr, "daemon already running, pid=%d\n", otherpid);
      }
      else
      {
	fprintf(stderr, "cannot open or create pid file\n");
	perror("pidfile_open");
      }
      return 1;
    }

    if (daemon(0, 0) != 0)
    {
      fprintf(stderr, "cannot daemonize\n");
      perror("daemon");
      pidfile_remove(pfh);
      return 8;
    }
  }

  if (pfh != NULL)
  {
    pidfile_write(pfh);
  }

  syslog(LOG_INFO, SYSLOG_PROGRAM_NAME " version '%s'",  IRCDDBD_VERSION );

  setenv("PACKAGE_VERSION", IRCDDBD_VERSION, 1);

  r = chdir( argv[2] );

  if (r < 0)
  {
    syslog(LOG_ERR, "chdir <working dir> failed, errno %d", errno);
    return 1;
  }

  int fd;

  fd = open( argv[3], O_WRONLY | O_CREAT | O_APPEND, 0644 );

  if (fd < 0)
  {
    syslog(LOG_ERR, "open <stdout file> failed, errno %d", errno);
    return 1;
  }


  r = dup2( fd, 1 );

  if (r < 0)
  {
    syslog(LOG_ERR, "dup2 <stdout file> failed, errno %d", errno);
    return 1;
  }

  close(fd);

  fd = open( argv[4], O_WRONLY | O_CREAT | O_APPEND, 0644 );

  if (fd < 0)
  {
    syslog(LOG_ERR, "open <stderr file> failed, errno %d", errno);
    return 1;
  }

  r = dup2( fd, 2 );

  if (r < 0)
  {
    syslog(LOG_ERR, "dup2 <stderr file> failed, errno %d", errno);
    return 1;
  }

  close(fd);


  while (end_flag == 0)
  {
    int i;
    int download_failed = 0;

    r = system("/usr/bin/curl --fail --connect-timeout 5 --max-time 15  $URL/$FILE1 -o $VARDIR/$FILE1");

    if (r != 0)
    {
      syslog(LOG_ERR, "system (file1) failed, errno %d, return value %d", errno, r);
      download_failed = 1;
    }

    r = system("/usr/bin/curl --fail --connect-timeout 5 --max-time 15  $URL/$FILE2 -o $VARDIR/$FILE2");

    if (r != 0)
    {
      syslog(LOG_ERR, "system (file2) failed, errno %d, return value %d", errno, r);
      download_failed = 1;
    }

    if (download_failed)
    {
      syslog(LOG_ERR, "software download failed, waiting 30 seconds");
      for (i=0; (i < 30) && (end_flag == 0); i++)
      {
	sleep(1);
      }
    }
    else
    {
      int count = 0;
      pid = fork();

      if (pid < 0)
      {
	syslog(LOG_ERR, "fork failed %d, waiting 30 seconds", errno);
	for (i=0; (i < 30) && (end_flag == 0); i++)
	{
	  sleep(1);
	}
      }
      else
      {
	if (pid == 0) // child
	{
	  execl( getenv("EXECBIN"), getenv("EXECBIN"), getenv("ARG1"),
	    getenv("ARG2"), getenv("ARG3"),
	    getenv("ARG4"), getenv("ARG5"),
	    (char*) 0 );

	  syslog(LOG_ERR, "execl failed %d", errno);
	  return 1;
	}
      }

      syslog(LOG_INFO, "process %d started", pid);

      while (end_flag == 0)
      {
	r = waitpid( pid, 0, WNOHANG);

	if (r == pid)
	{
	  syslog(LOG_INFO, "process %d ended after %d seconds", pid, count);
	  pid = 0;
	  break;
	}
	count ++;
	sleep(1);
      }

      i = 10;

      if (count < 20)
      {
	syslog(LOG_ERR, "process exited too quickly, waiting 120 seconds");
	i = 120;
      }

      for (; (end_flag == 0) && (i > 0); i--)
      {
	sleep(1);
      }
    }

  }

  if (pfh != NULL)
  {
    pidfile_remove(pfh);
  }

  syslog(LOG_INFO, "stop");
  return 0;
}


