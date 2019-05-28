For all rolling 10 minute, windows extract current and future sale
for the same product at the same price.
If the same product and price does not appear twice in a rolling window do not extract
the singleton sale.

https://tinyurl.com/y49p2nvb
https://github.com/rogerjdeangelis/utl-how-to-compare-price-observations-in-rolling-time-intervals

Stackoverflow
https://tinyurl.com/y2b72gob
https://stackoverflow.com/questions/46712379/efficient-way-to-fill-time-series-per-group

Sotos Profile
https://stackoverflow.com/users/5635580/sotos


  There are many other faster methods using a HASH, Arrays, Merge and/or DOW.
  SQL is just one. Too lazy to show more solutions. This solution may be reasonable
  for small LOCAL groups or moderate LOCAL groups with good locality of reference,
  ie notsorted but grouped. If the groups are large but few
  you can do groups in parallel.
*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;

data have ;
input @1 PRICE 1. @6 PRODUCT $3. @12 DATE anydtdtm15.;
format date datetime17.;
datalines;
1    POW   JAN-01-17 13:00
2    POW   JAN-01-17 13:04
1    POW   JAN-01-17 13:06
2    POW   JAN-01-17 13:15
1    POW   JAN-01-17 13:20
5    POW   JAN-01-17 13:29
1    GAS   JAN-01-17 13:05
2    GAS   JAN-01-17 13:10
1    GAS   JAN-01-17 13:39
1    GAS   JAN-01-17 13:42
1    GAS   JAN-01-17 13:52
;;;;
run;


HAVE total obs=11

Obs    PRODUCT PRICE         DATE

  1      POW     1     01JAN17:13:00:00
  2      POW     2     01JAN17:13:04:00
  3      POW     1     01JAN17:13:06:00
  4      POW     2     01JAN17:13:15:00
  5      POW     1     01JAN17:13:20:00
  6      POW     5     01JAN17:13:29:00
  7      GAS     1     01JAN17:13:05:00
  8      GAS     2     01JAN17:13:10:00
  9      GAS     1     01JAN17:13:39:00
 10      GAS     1     01JAN17:13:42:00
 11      GAS     1     01JAN17:13:52:00


*           _
 _ __ _   _| | ___  ___
| '__| | | | |/ _ \/ __|
| |  | |_| | |  __/\__ \
|_|   \__,_|_|\___||___/

;


WANT total obs=11
                                                     | RULES
                                        SAME_PRICED_ | =====
  PRODUCT PRICE       DATE               FUTURE_DATE |
                                                     |
    POW     1   01JAN17:13:00:00    01JAN17:13:06:00 |  window 13:00-13:10 we have a repeat sale - same price-> mark
    POW     2   01JAN17:13:04:00                   . |  window 13:01-13:11 we do NOT have a repeat sale
    POW     1   01JAN17:13:06:00                   . |  ..
    POW     2   01JAN17:13:15:00                   . |  ..
    POW     3   01JAN17:13:20:00                   . |  ..
    POW     1   01JAN17:13:29:00                   . |  same price but only in one window
                                                     |
                                                     |
    GAS     1   01JAN17:13:05:00                   . | 34 minutes to next sale - singeton
    GAS     2   01JAN17:13:10:00                   . |
    GAS     1   01JAN17:13:39:00    01JAN17:13:42:00 | window 13:39 to 13:49 has a repeat sale
    GAS     1   01JAN17:13:42:00    01JAN17:13:52:00 | window 13:42 to 13:52 has a repeat sale
    GAS     1   01JAN17:13:52:00                   . |


*            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;

WORKWANT total obs=11

                                             SAME_PRICED_
 PRICE    PRODUCT          DATE               FUTURE_DATE      DELTA

   1        GAS      01JAN17:13:05:00                   .          .
   2        GAS      01JAN17:13:10:00                   .          .
   1        GAS      01JAN17:13:39:00    01JAN17:13:42:00    0:03:00
   1        GAS      01JAN17:13:42:00    01JAN17:13:52:00    0:10:00
   1        GAS      01JAN17:13:52:00                   .          .
   1        POW      01JAN17:13:00:00    01JAN17:13:06:00    0:06:00
   2        POW      01JAN17:13:04:00                   .          .
   1        POW      01JAN17:13:06:00                   .          .
   2        POW      01JAN17:13:15:00                   .          .
   1        POW      01JAN17:13:20:00                   .          .
   5        POW      01JAN17:13:29:00                   .          .

*
 _ __  _ __ ___   ___ ___  ___ ___
| '_ \| '__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|
;

data have ;
input @1 PRICE 1. @6 PRODUCT $3. @12 DATE anydtdtm15.;
format date datetime17.;
datalines;
1    POW   JAN-01-17 13:00
2    POW   JAN-01-17 13:04
1    POW   JAN-01-17 13:06
2    POW   JAN-01-17 13:15
1    POW   JAN-01-17 13:20
5    POW   JAN-01-17 13:29
1    GAS   JAN-01-17 13:05
2    GAS   JAN-01-17 13:10
1    GAS   JAN-01-17 13:39
1    GAS   JAN-01-17 13:42
1    GAS   JAN-01-17 13:52
;;;;
run;


proc sql;
  create
      table want as
  select self.*
      ,twin.date           as same_priced_future_date
      ,twin.date-self.date as delta format=time8.
  from
     have as self left join have as twin
  on
     self.product            = twin.product
     and self.price          = twin.price
     and self.date           < twin.date
     and twin.date-self.date <= '00:10:00't
  order
     by self.product
    ,self.date
    ,twin.date
;quit;






