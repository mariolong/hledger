{-# LANGUAGE CPP #-}
{-|

A ledger-compatible @balance@ command.

ledger's balance command is easy to use but not easy to describe
precisely.  In the examples below we'll use sample.journal, which has the
following account tree:

@
 assets
   bank
     checking
     saving
   cash
 expenses
   food
   supplies
 income
   gifts
   salary
 liabilities
   debts
@

The balance command shows accounts with their aggregate balances.
Subaccounts are displayed indented below their parent. Each balance is the
sum of any transactions in that account plus any balances from
subaccounts:

@
 $ hledger -f sample.journal balance
                 $-1  assets
                  $1    bank:saving
                 $-2    cash
                  $2  expenses
                  $1    food
                  $1    supplies
                 $-2  income
                 $-1    gifts
                 $-1    salary
                  $1  liabilities:debts
@

Usually, the non-interesting accounts are elided or omitted. Above,
@checking@ is omitted because it has no subaccounts and a zero balance.
@bank@ is elided because it has only a single displayed subaccount
(@saving@) and it would be showing the same balance as that ($1). Ditto
for @liabilities@. We will return to this in a moment.

The --depth argument can be used to limit the depth of the balance report.
So, to see just the top level accounts:

@
$ hledger -f sample.journal balance --depth 1
                 $-1  assets
                  $2  expenses
                 $-2  income
                  $1  liabilities
@

This time liabilities has no displayed subaccounts (due to --depth) and
is not elided.

With one or more account pattern arguments, the balance command shows
accounts whose name matches one of the patterns, plus their parents
(elided) and subaccounts. So with the pattern o we get:

@
 $ hledger -f sample.journal balance o
                  $1  expenses:food
                 $-2  income
                 $-1    gifts
                 $-1    salary
--------------------
                 $-1
@

The o pattern matched @food@ and @income@, so they are shown. Unmatched
parents of matched accounts are also shown (elided) for context (@expenses@).

Also, the balance report shows the total of all displayed accounts, when
that is non-zero. Here, it is displayed because the accounts shown add up
to $-1.

Here is a more precise definition of \"interesting\" accounts in ledger's
balance report:

- an account which has just one interesting subaccount branch, and which
  is not at the report's maximum depth, is interesting if the balance is
  different from the subaccount's, and otherwise boring.

- any other account is interesting if it has a non-zero balance, or the -E
  flag is used.

-}

module Hledger.Cli.Balance (
  balance
 ,accountsReportAsText
 ,tests_Hledger_Cli_Balance
) where

import Data.List
import Data.Maybe
import Test.HUnit

import Hledger
import Prelude hiding (putStr)
import Hledger.Utils.UTF8 (putStr)
import Hledger.Cli.Format
import qualified Hledger.Cli.Format as Format
import Hledger.Cli.Options
import Hledger.Cli.Reports


-- | Print a balance report.
balance :: CliOpts -> Journal -> IO ()
balance CliOpts{reportopts_=ropts} j = do
  d <- getCurrentDay
  let lines = case formatFromOpts ropts of
            Left err -> [err]
            Right _ -> accountsReportAsText ropts $ accountsReport ropts (optsToFilterSpec ropts d) j
  putStr $ unlines lines

-- | Render a balance report as plain text suitable for console output.
accountsReportAsText :: ReportOpts -> AccountsReport -> [String]
accountsReportAsText opts (items, total) = concat lines ++ t
    where
      lines = case formatFromOpts opts of
                Right f -> map (accountsReportItemAsText opts f) items
                Left err -> [[err]]
      t = if no_total_ opts
           then []
           else ["--------------------"
                 -- TODO: This must use the format somehow
                ,padleft 20 $ showMixedAmountWithoutPrice total
                ]

{-
This implementation turned out to be a bit convoluted but implements the following algorithm for formatting:

- If there is a single amount, print it with the account name directly:
- Otherwise, only print the account name on the last line.

    a         USD 1   ; Account 'a' has a single amount
              EUR -1
    b         USD -1  ; Account 'b' has two amounts. The account name is printed on the last line.
-}
-- | Render one balance report line item as plain text.
accountsReportItemAsText :: ReportOpts -> [FormatString] -> AccountsReportItem -> [String]
accountsReportItemAsText opts format (_, accountName, depth, Mixed amounts) =
    case amounts of
      [] -> []
      [a] -> [formatAccountsReportItem opts (Just accountName) depth a format]
      (as) -> asText as
    where
      asText :: [Amount] -> [String]
      asText []     = []
      asText [a]    = [formatAccountsReportItem opts (Just accountName) depth a format]
      asText (a:as) = (formatAccountsReportItem opts Nothing depth a format) : asText as

formatAccountsReportItem :: ReportOpts -> Maybe AccountName -> Int -> Amount -> [FormatString] -> String
formatAccountsReportItem _ _ _ _ [] = ""
formatAccountsReportItem opts accountName depth amount (fmt:fmts) =
  s ++ (formatAccountsReportItem opts accountName depth amount fs)
  where
    s = case fmt of
         FormatLiteral l -> l
         FormatField ljust min max field  -> formatField opts accountName depth amount ljust min max field

formatField :: ReportOpts -> Maybe AccountName -> Int -> Amount -> Bool -> Maybe Int -> Maybe Int -> Field -> String
formatField opts accountName depth balance ljust min max field = case field of
        Format.Account     -> formatValue ljust min max a
        Format.DepthSpacer -> case min of
                               Just m  -> formatValue ljust Nothing max $ replicate (depth * m) ' '
                               Nothing -> formatValue ljust Nothing max $ replicate depth ' '
        Format.Total       -> formatValue ljust min max $ showAmountWithoutPrice balance
        _                  -> ""
    where
      a = maybe "" (accountNameDrop (drop_ opts)) accountName

tests_Hledger_Cli_Balance = TestList
 [
 ]
