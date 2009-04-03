{-|

A 'TimeLog' is a parsed timelog file (see timeclock.el or the command-line
version) containing zero or more 'TimeLogEntry's. It can be converted to a
'RawLedger' for querying.

-}

module Ledger.TimeLog
where
import Ledger.Utils
import Ledger.Types
import Ledger.Dates
import Ledger.Commodity
import Ledger.Amount
import Ledger.LedgerTransaction

instance Show TimeLogEntry where 
    show t = printf "%s %s %s" (show $ tlcode t) (show $ tldatetime t) (tlcomment t)

instance Show TimeLog where
    show tl = printf "TimeLog with %d entries" $ length $ timelog_entries tl

-- | Convert time log entries to ledger transactions. When there is no
-- clockout, add one with the provided current time. Sessions crossing
-- midnight are split into days to give accurate per-day totals.
entriesFromTimeLogEntries :: LocalTime -> [TimeLogEntry] -> [LedgerTransaction]
entriesFromTimeLogEntries _ [] = []
entriesFromTimeLogEntries now [i]
    | odate > idate = [entryFromTimeLogInOut i o'] ++ entriesFromTimeLogEntries now [i',o]
    | otherwise = [entryFromTimeLogInOut i o]
    where
      o = TimeLogEntry 'o' end ""
      end = if itime > now then itime else now
      (itime,otime) = (tldatetime i,tldatetime o)
      (idate,odate) = (localDay itime,localDay otime)
      o' = o{tldatetime=itime{localDay=idate, localTimeOfDay=TimeOfDay 23 59 59}}
      i' = i{tldatetime=itime{localDay=addDays 1 idate, localTimeOfDay=midnight}}
entriesFromTimeLogEntries now (i:o:rest)
    | odate > idate = [entryFromTimeLogInOut i o'] ++ entriesFromTimeLogEntries now (i':o:rest)
    | otherwise = [entryFromTimeLogInOut i o] ++ entriesFromTimeLogEntries now rest
    where
      (itime,otime) = (tldatetime i,tldatetime o)
      (idate,odate) = (localDay itime,localDay otime)
      o' = o{tldatetime=itime{localDay=idate, localTimeOfDay=TimeOfDay 23 59 59}}
      i' = i{tldatetime=itime{localDay=addDays 1 idate, localTimeOfDay=midnight}}

-- | Convert a timelog clockin and clockout entry to an equivalent ledger
-- entry, representing the time expenditure. Note this entry is  not balanced,
-- since we omit the \"assets:time\" transaction for simpler output.
entryFromTimeLogInOut :: TimeLogEntry -> TimeLogEntry -> LedgerTransaction
entryFromTimeLogInOut i o
    | otime >= itime = t
    | otherwise = 
        error $ "clock-out time less than clock-in time in:\n" ++ showLedgerTransaction t
    where
      t = LedgerTransaction {
            ltdate         = idate,
            ltstatus       = True,
            ltcode         = "",
            ltdescription  = showtime itod ++ "-" ++ showtime otod,
            ltcomment      = "",
            ltpostings = ps,
            ltpreceding_comment_lines=""
          }
      showtime = take 5 . show
      acctname = tlcomment i
      itime    = tldatetime i
      otime    = tldatetime o
      itod     = localTimeOfDay itime
      otod     = localTimeOfDay otime
      idate    = localDay itime
      odate    = localDay otime
      hrs      = elapsedSeconds (toutc otime) (toutc itime) / 3600 where toutc = localTimeToUTC utc
      amount   = Mixed [hours hrs]
      ps       = [Posting False acctname amount "" RegularPosting
                 --,Posting "assets:time" (-amount) "" RegularPosting
                 ]
