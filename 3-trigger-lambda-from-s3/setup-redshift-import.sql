CREATE TABLE indicator_result
(
	symbol varchar(10),
	candle_date datetime sortkey,
	open_price decimal(19,9) NULL,
	high_price decimal(19,9) NULL,
	low_price decimal(19,9) NULL,
	close_price decimal(19,9) NULL,
	candle_direction smallint NULL,
	atr decimal(19,9) NULL,
	indicator_name varchar(20),
	indicator_setting smallint,
	indicator_direction smallint NULL,
	indicator_signal smallint NULL,
	win_1_atr smallint NULL,
	win_2_atr smallint NULL,
	finish_date datetime NULL,
	PRIMARY KEY (symbol, candle_date, indicator_name, indicator_setting)
);

CREATE TABLE indicator_staging
(
	symbol varchar(10),
	candle_date datetime sortkey,
	open_price decimal(19,9) NULL,
	high_price decimal(19,9) NULL,
	low_price decimal(19,9) NULL,
	close_price decimal(19,9) NULL,
	candle_direction smallint NULL,
	atr decimal(19,9) NULL,
	indicator_name varchar(20),
	indicator_setting smallint,
	indicator_direction smallint NULL,
	indicator_signal smallint NULL,
	PRIMARY KEY (symbol, candle_date, indicator_name, indicator_setting)
);

CREATE OR REPLACE PROCEDURE process_staging()
AS $$
BEGIN
	insert into indicator_result
	(
		symbol,
		candle_date,
		open_price,
		high_price,
		low_price,
		close_price,
		candle_direction,
		atr,
		indicator_name,
		indicator_setting,
		indicator_direction,
		indicator_signal
	)
	select s.symbol,
		s.candle_date,
		s.open_price,
		s.high_price,
		s.low_price,
		s.close_price,
		s.candle_direction,
		s.atr,
		s.indicator_name,
		s.indicator_setting,
		s.indicator_direction,
		s.indicator_signal
	from indicator_staging s
		LEFT join indicator_result r on r.symbol = s.symbol
			and r.candle_date = s.candle_date
			and r.indicator_name = s.indicator_name
			and r.indicator_setting = s.indicator_setting
	where r.Symbol is null;
END;
$$
LANGUAGE plpgsql
;

CREATE OR REPLACE PROCEDURE delete_processed()
AS $$
BEGIN
	delete
	from indicator_staging
    using indicator_staging as s
	left outer join indicator_result r on r.symbol = s.symbol
        	and r.candle_date = s.candle_date
            and r.indicator_name = s.indicator_name
            and r.indicator_setting = s.indicator_setting
	where r.Symbol is not null;
END;
$$
LANGUAGE plpgsql
;
