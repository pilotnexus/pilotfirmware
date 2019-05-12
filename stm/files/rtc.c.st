#include "rtc.h"

#ifdef STM32F4XX

/* sets the time of the realtime clock */
static void rtc_set_time_bin(uint8_t hours, uint8_t minutes, uint8_t seconds)
{
  RTC_TimeTypeDef time;

  time.RTC_Hours   = hours;
  time.RTC_Minutes = minutes;
  time.RTC_Seconds = seconds; 

  /* set the time */
  RTC_SetTime(RTC_Format_BIN, &time);
}

/* sets the date of the realtime clock */
static void rtc_set_date_bin(uint8_t year, uint8_t month, uint8_t dayOfMonth, uint8_t weekday)
{
  RTC_DateTypeDef date;

  date.RTC_Year    = year;
  date.RTC_Month   = month;
  date.RTC_Date    = dayOfMonth;
  date.RTC_WeekDay = weekday;

  /* set the date */
  RTC_SetDate(RTC_Format_BIN, &date);
}

/* fills the time of the realtime clock */
static void rtc_get_time_bin(RTC_TimeTypeDef* time)
{
  /* fill the time struct */
  RTC_GetTime(RTC_Format_BIN, time);
}

static void rtc_get_date_bin(RTC_DateTypeDef* date)
{
  RTC_GetDate(RTC_Format_BIN, date);
}

#endif

static void rtc_configure()
{
#ifdef STM32F4XX
  /* configure the RTC data register and RTC prescalar */
  RTC_InitTypeDef rtc;
  rtc.RTC_AsynchPrediv = 0xff;
  rtc.RTC_SynchPrediv  = 0x7f;
  rtc.RTC_HourFormat   = RTC_HourFormat_24;
  RTC_Init(&rtc);
#else /* STM32F10X_HD */
  /* Wait until last write operation on RTC registers has finished */
  RTC_WaitForLastTask();

  /* Enable the RTC Second */
  RTC_ITConfig(RTC_IT_SEC, ENABLE);

  /* Wait until last write operation on RTC registers has finished */
  RTC_WaitForLastTask();

  /* Set RTC prescaler: set RTC period to 1sec */
  RTC_SetPrescaler(32767); /* RTC period = RTCCLK/RTC_PR = (32.768 KHz)/(32767+1) */

  /* Wait until last write operation on RTC registers has finished */
  RTC_WaitForLastTask();
#endif
}

/* fills the supplied cmd */
void rtc_get_datetime_cmd(pilot_cmd_t* cmd)
{
#ifdef STM32F4XX
  RTC_DateTypeDef date;
  RTC_TimeTypeDef time;

  /* clear the struct */
  memset(cmd, 0, sizeof(pilot_cmd_t));

  rtc_get_time_bin(&time); /* retrieve the time from the rtc */
  rtc_get_date_bin(&date); /* retrieve the date from the rtc */

  cmd->target = target_base;
  cmd->type   = pilot_cmd_type_rtc_get;

  /* set the time components */
  cmd->data[pilot_rtc_index_hours]   = time.RTC_Hours;
  cmd->data[pilot_rtc_index_minutes] = time.RTC_Minutes;
  cmd->data[pilot_rtc_index_seconds] = time.RTC_Seconds;

  /* set the date components */
  cmd->data[pilot_rtc_index_dayofmonth] = date.RTC_Date;
  cmd->data[pilot_rtc_index_weekday]    = date.RTC_WeekDay;
  cmd->data[pilot_rtc_index_month]      = date.RTC_Month;
  cmd->data[pilot_rtc_index_year]       = date.RTC_Year;
#else /* STM32F10X_HD */

  time_t rawtime;
  struct tm* ptm;

  /* get the current second counter */
  rawtime = (time_t) RTC_GetCounter();

#ifdef KEIL
   ptm = gmtime(&rawtime);
#else
  struct tm timeinfo;
  memset(&timeinfo, 0, sizeof(struct tm));

  /* use standard c library function to convert seconds since 1/1/1970 to a struct tm */
  gmtime_r(&rawtime, &timeinfo);
  ptm = &timeinfo;
#endif

  /* fill the cmd struct */
  memset(cmd, 0, sizeof(pilot_cmd_t)); /* clear the struct */
  cmd->target = target_base;
  cmd->type   = pilot_cmd_type_rtc_get;
  cmd->data[pilot_rtc_index_hours]      = ptm->tm_hour;
  cmd->data[pilot_rtc_index_minutes]    = ptm->tm_min;
  cmd->data[pilot_rtc_index_seconds]    = ptm->tm_sec;
  cmd->data[pilot_rtc_index_dayofmonth] = ptm->tm_mday;
  cmd->data[pilot_rtc_index_weekday]    = ptm->tm_wday;
  cmd->data[pilot_rtc_index_month]      = ptm->tm_mon;
  cmd->data[pilot_rtc_index_year]       = ptm->tm_year;
#endif
  cmd->length = MSG_LEN(8);
}


#ifndef STM32F4XX

#define _SEC_IN_MINUTE 60L
#define _SEC_IN_HOUR 3600L
#define _SEC_IN_DAY 86400L

static const int DAYS_IN_MONTH[12] =
{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

#define _DAYS_IN_MONTH(x) ((x == 1) ? days_in_feb : DAYS_IN_MONTH[x])

static const int _DAYS_BEFORE_MONTH[12] =
{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334};

#define _ISLEAP(y) (((y) % 4) == 0 && (((y) % 100) != 0 || (((y)+1900) % 400) == 0))
#define _DAYS_IN_YEAR(year) (_ISLEAP(year) ? 366 : 365)

static time_t mktime_fix(struct tm *tim_p)
{
  time_t tim = 0;
  long days = 0;
  int year, isdst, tm_isdst;

  /* compute hours, minutes, seconds */
  tim += tim_p->tm_sec + (tim_p->tm_min * _SEC_IN_MINUTE) +
    (tim_p->tm_hour * _SEC_IN_HOUR);

  /* compute days in year */
  days += tim_p->tm_mday - 1;
  days += _DAYS_BEFORE_MONTH[tim_p->tm_mon];
  if (tim_p->tm_mon > 1 && _DAYS_IN_YEAR (tim_p->tm_year) == 366)
    days++;

  /* compute day of the year */
  tim_p->tm_yday = days;

  if (tim_p->tm_year > 10000
      || tim_p->tm_year < -10000)
    {
      return (time_t) -1;
    }

  /* compute days in other years */
  if (tim_p->tm_year > 70)
    {
      for (year = 70; year < tim_p->tm_year; year++)
  days += _DAYS_IN_YEAR (year);
    }
  else if (tim_p->tm_year < 70)
    {
      for (year = 69; year > tim_p->tm_year; year--)
  days -= _DAYS_IN_YEAR (year);
      days -= _DAYS_IN_YEAR (year);
    }

  /* compute day of the week */
  if ((tim_p->tm_wday = (days + 4) % 7) < 0)
    tim_p->tm_wday += 7;

  /* compute total seconds */
  tim += (days * _SEC_IN_DAY);

  return tim;
}
#endif

/* sets the rtc datetime from the supplied command */
void rtc_set_datetime_cmd(pilot_cmd_t* cmd)
{
#ifdef STM32F4XX
  uint8_t hours, minutes, seconds;
  uint8_t year, month, dayOfMonth, weekday;

  /* set the time */
  hours   = cmd->data[pilot_rtc_index_hours];
  minutes = cmd->data[pilot_rtc_index_minutes];
  seconds = cmd->data[pilot_rtc_index_seconds];
  rtc_set_time_bin(hours, minutes, seconds);

  /* set the date */
  year       = cmd->data[pilot_rtc_index_year];
  month      = cmd->data[pilot_rtc_index_month];
  dayOfMonth = cmd->data[pilot_rtc_index_dayofmonth];
  weekday    = cmd->data[pilot_rtc_index_weekday];
  rtc_set_date_bin(year, month, dayOfMonth, weekday);
#else /* STM32F10X_HD */
  time_t rawtime;
  struct tm timeinfo;

  rawtime = 0;
  memset(&timeinfo, 0, sizeof(struct tm));

  /* fill the struct tm */
  timeinfo.tm_hour = cmd->data[pilot_rtc_index_hours];
  timeinfo.tm_min  = cmd->data[pilot_rtc_index_minutes];
  timeinfo.tm_sec  = cmd->data[pilot_rtc_index_seconds];
  timeinfo.tm_mday = cmd->data[pilot_rtc_index_dayofmonth];
  timeinfo.tm_wday = cmd->data[pilot_rtc_index_weekday];
  timeinfo.tm_mon  = cmd->data[pilot_rtc_index_month];
  timeinfo.tm_year = cmd->data[pilot_rtc_index_year];

  /* use standard c library function to convert struct tm to seconds since 1/1/1970 */
  rawtime = mktime_fix(&timeinfo);

  /* reset the counter if the time is invalid */
  if (rawtime == -1)
    RTC_SetCounter(0);
  else
    RTC_SetCounter((uint32_t)rawtime); /* store the seconds elapsed since 1/1/1970 in the rtc */

#endif
}

$if(model.debug)$
#ifdef STM32F4XX
void rtc_debug_test_set()
{
  rtc_set_date_bin(13, 10, 14, 1);
  rtc_set_time_bin(15, 40, 0);
}

void rtc_debug_test_get()
{
  RTC_DateTypeDef date;
  RTC_TimeTypeDef time;

  rtc_get_time(&time);
  rtc_get_date(&date);
}
#endif
$endif$

static void rtc_configure_init()
{
#ifdef STM32F4XX
  /* enable the PWR clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR, ENABLE);

  /* Allow access to RTC */
  PWR_BackupAccessCmd(ENABLE);

  /* enable the LSE OSC */
  RCC_LSEConfig(RCC_LSE_ON);

  /* wait until LSE is ready */
  while(RCC_GetFlagStatus(RCC_FLAG_LSERDY) == RESET);

  /* select the RTC clock source */
  RCC_RTCCLKConfig(RCC_RTCCLKSource_LSE);

  /* enable the RTC clock */
  RCC_RTCCLKCmd(ENABLE);

  /* wait for RTC APB registers synchronisation */
  RTC_WaitForSynchro();
#else /* STM32F10X_HD */
   /* Enable PWR and BKP clocks */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR | RCC_APB1Periph_BKP, ENABLE);

  /* Allow access to BKP Domain */
  PWR_BackupAccessCmd(ENABLE);

  /* Enable LSE */
  RCC_LSEConfig(RCC_LSE_ON);

  /* Wait till LSE is ready */
  while (RCC_GetFlagStatus(RCC_FLAG_LSERDY) == RESET);

  /* Select LSE as RTC Clock Source */
  RCC_RTCCLKConfig(RCC_RTCCLKSource_LSE);

  /* Enable RTC Clock */
  RCC_RTCCLKCmd(ENABLE);

  /* Wait for RTC registers synchronization */
  RTC_WaitForSynchro();
#endif
}

/* initialize the rtc */
void rtc_init()
{
  pilot_usart_send_string("initializing rtc...");
  rtc_configure_init();
  pilot_usart_send_string("DONE\r\n");

  pilot_usart_send_string("configuring rtc...");
  rtc_configure();
  pilot_usart_send_string("DONE\r\n");
}
