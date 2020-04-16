CREATE OR REPLACE function f_calculate_roi(int, int, int)
returns decimal(19, 9)
stable
AS $$
	select cast(power(cast((1.0 + .01 * (1.0 / 1.5)) as decimal(19,9)), $1) * power(cast((1.0 + .01 * (2.0 / 1.5)) as decimal(19,9)), $2) * power(.98, $3 - $1) as decimal(19,9));
$$
LANGUAGE sql
;

CREATE OR REPLACE PROCEDURE roi_symbol_indicator_setting(datetime, datetime)
AS $$
BEGIN
	DROP TABLE if exists result_symbol_indicator;
	create table result_symbol_indicator
	(
		symbol varchar(10),
		indicator_name varchar(20),
		indicator_setting smallint,
		win1 bigint,
		win2 bigint,
		total bigint,
		roi decimal(19,9)
	);
	insert into result_symbol_indicator
	select r.symbol,
		r.indicator_name,
		r.indicator_setting,
		sum(r.win_1_atr) as win1,
		sum(r.win_2_atr) as win2,
		count(r.win_1_atr) as total,
		f_calculate_roi(sum(r.win_1_atr), sum(r.win_2_atr), count(r.win_1_atr)) roi
	from indicator_result r
	where r.candle_date >= $1
		and r.candle_date <= $2
		and r.indicator_signal = 1
	group by r.symbol,
		r.indicator_name,
		r.indicator_setting;
END;
$$
LANGUAGE plpgsql
;
