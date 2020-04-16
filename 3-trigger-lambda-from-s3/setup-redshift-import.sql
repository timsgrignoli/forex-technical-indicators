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

CREATE OR REPLACE PROCEDURE calculate_wins()
AS $$
declare symbol_var varchar(10);
	candle_date_var datetime;
	direction_var smallint;
	stop_loss_atr_factor decimal(19, 9) := 1.5;
	stop_loss decimal(19, 9);
	take_profit_1_atr_factor decimal(19, 9) := 1.0;
	take_profit_1 decimal(19, 9);
	take_profit_2_atr_factor decimal(19, 9) := 2.0;
	take_profit_2 decimal(19, 9);
	close_price_var decimal(19, 9);
	win1 int := 0;
	loop_start int := 0;
	loop_end int;
	loop_start2 int := 1;
	loop_end2 int;
	high_var decimal(19, 9);
	low_var decimal(19, 9);
	finish_var datetime;
BEGIN

	-- refer to the README for Calculate Wins on Github for detailed explanation https://github.com/timsgrignoli/forex-technical-indicators
	-- table to loop through to calculate
	DROP TABLE if exists result_table;
	create temp table result_table
	(
		row_num int,
		symbol varchar(10),
		candle_date datetime,
		indicator_direction smallint,
		win_1_atr smallint,
		win_2_atr smallint,
		finish_date datetime
	);
	
	-- insert distinct symbol candle_date and direction for all unfinished
	insert into result_table
	(
		row_num,
		symbol,
		candle_date,
		indicator_direction
	)
	select ROW_NUMBER() over(order by symbol) row_num,
		symbol,
		candle_date,
		indicator_direction
	from
	(
		select distinct
			i.symbol,
			i.candle_date,
			i.indicator_direction
		from indicator_result i
		where i.indicator_signal = 1
			and i.finish_date is null
	) a;
	
	select into loop_end MAX(t.row_num)
	from result_table t;

	<<outer_loop>>
	while loop_start < loop_end
	loop
		loop_start = loop_start + 1;	

		select into
			symbol_var,
			candle_date_var,
			direction_var
			r.symbol,
			r.candle_date,
			r.indicator_direction
		from result_table r
		where r.row_num = loop_start;
		
		select into
			stop_loss,
			take_profit_1,
			take_profit_2,
			close_price_var
			case direction_var when 1 then i.close_price - stop_loss_atr_factor * i.atr
					when -1 then i.close_price + stop_loss_atr_factor * i.atr
					else null
				end,
			case direction_var when 1 then i.close_price + take_profit_1_atr_factor * i.atr
					when -1 then i.close_price - take_profit_1_atr_factor * i.atr
					else null
				end,
			case direction_var when 1 then i.close_price + take_profit_2_atr_factor * i.atr
					when -1 then i.close_price - take_profit_2_atr_factor * i.atr
					else null
				end,
			i.close_price
		from indicator_result i
		where i.symbol = symbol_var
			and i.candle_date = candle_date_var
		limit 1;
		
		-- symbol/date combo gave null values
		if stop_loss is null
			or take_profit_1 is null
			or take_profit_2 is null
		then
			continue outer_loop;
		end if;
		
		-- insert distinct OHLC and Atr for symbol by date since candle_date
		DROP TABLE if exists loop_table;
		create temp table loop_table
		(
			row_num int,
			symbol varchar(10),
			candle_date datetime,
			open_price decimal(19, 9),
			high_price decimal(19, 9),
			low_price decimal(19, 9),
			close_price decimal(19, 9),
			atr decimal(19, 9)
		);
		insert into loop_table
		select distinct
			DENSE_RANK() over(order by i.candle_date),
			i.symbol,
			i.candle_date,
			i.open_price,
			i.high_price,
			i.low_price,
			i.close_price,
			i.atr
		from indicator_result i
		where i.symbol = symbol_var
			and i.candle_date >= candle_date_var;

		loop_start2 = 1;
		select into loop_end2 MAX(t.row_num)
		from loop_table t;
		finish_var = null;
		win1 = 0;
		
		while loop_start2 < loop_end2
		loop
			loop_start2 = loop_start2 + 1;
			select into
				low_var,
				high_var,
				finish_var
				t.low_price,
				t.high_price,
				t.candle_date
			from loop_table t
			where t.row_num = loop_start2;
			
			-- going long
			if direction_var > 0
			then
				if low_var <= stop_loss
				then
					update result_table
						set win_1_atr = win1,
							win_2_atr = 0,
							finish_date = finish_var
					where symbol = symbol_var
						and candle_date = candle_date_var
						and indicator_direction = direction_var;
					continue outer_loop;
				end if;

				if high_var >= take_profit_1
				then
					win1 = 1;
					stop_loss = close_price_var;
					if high_var >= take_profit_2
					then
						update result_table
							set win_1_atr = win1,
								win_2_atr = 1,
								finish_date = finish_var
						where symbol = symbol_var
							and candle_date = candle_date_var
							and indicator_direction = direction_var;
						continue outer_loop;
					end if;
				end if;
				
			-- going short
			elsif direction_var < 0
			then
				if high_var >= stop_loss
				then
					update result_table
						set win_1_atr = win1,
							win_2_atr = 0,
							finish_date = finish_var
					where symbol = symbol_var
						and candle_date = candle_date_var
						and indicator_direction = direction_var;
					continue outer_loop;
				end if;

				if low_var <= take_profit_1
				then
					win1 = 1;
					stop_loss = close_price_var;
					if low_var <= take_profit_2
					then
						update result_table
							set win_1_atr = win1,
								win_2_atr = 1,
								finish_date = finish_var
						where symbol = symbol_var
							and candle_date = candle_date_var
							and indicator_direction = direction_var;
						continue outer_loop;
					end if;
				end if;
			end if;
		end loop;

	end loop;
	
	-- final update
	update indicator_result
	set win_1_atr = result_table.win_1_atr,
		win_2_atr = result_table.win_2_atr,
		finish_date = result_table.finish_date
	from result_table
	join indicator_result r on result_table.symbol = r.symbol
		and result_table.candle_date = r.candle_date
		and result_table.indicator_direction = r.indicator_direction
	where r.finish_date is null;
	
END;
$$
LANGUAGE plpgsql
;
