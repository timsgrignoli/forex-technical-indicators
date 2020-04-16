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
	DROP TABLE if exists symbol_indicator_result;
	create table symbol_indicator_result
	(
		symbol varchar(10),
		indicator_name varchar(20),
		indicator_setting smallint,
		win1 bigint,
		win2 bigint,
		total bigint,
		roi decimal(19,9)
	);
	insert into symbol_indicator_result
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

CREATE OR REPLACE PROCEDURE roi_strategy_simulation(datetime, datetime, datetime, datetime)
AS $$
BEGIN
	DROP TABLE if exists simulation_result;
	create table simulation_result
	(
		symbol varchar(10),
		indicator_name varchar(20),
		indicator_setting smallint,
		pre_total_signals bigint,
		pre_total_win1 bigint,
		pre_total_avg1 decimal(19, 9),
		pre_total_win2 bigint,
		pre_total_avg2 decimal(19, 9),
		pre_longest_lose_streak bigint,
		pre_roi decimal(19,9),
		post_total_signals bigint,
		post_total_win1 bigint,
		post_total_win2 bigint,
		post_roi decimal(19,9)
	);
	insert into simulation_result
	(
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	)
	select r.symbol,
		r.indicator_name,
		r.indicator_setting,
		count(r.win_1_atr),
		sum(r.win_1_atr),
		avg(cast(r.win_1_atr as decimal(19, 9))),
		sum(r.win_2_atr),
		avg(cast(r.win_2_atr as decimal(19, 9))),
		coalesce(lose.longest, 0),
		f_calculate_roi(sum(r.win_1_atr), sum(r.win_2_atr), count(r.win_1_atr)),
		r1.total,
		r1.wins1,
		r1.wins2,
		f_calculate_roi(r1.wins1, r1.wins2, r1.total)
	from indicator_result r
		left join
		(
			select rps.symbol,
				rps.indicator_name,
				rps.indicator_setting,
				max(rps.slength) as longest
			from
			(
				-- count lengths of streaks
				select COUNT(sn.symbol) as slength,
					sn.symbol,
					sn.indicator_name,
					sn.indicator_setting,
					sn.snum
				from
				(
					-- label streaks to find length
					select ns.symbol,
						ns.candle_date,
						ns.indicator_name,
						ns.indicator_setting,
						SUM(ns.streak) over(partition by ns.symbol,ns.indicator_name,ns.indicator_setting order by ns.symbol,ns.indicator_name,ns.indicator_setting,ns.candle_date rows unbounded preceding) as snum
					from
					(
						-- identify new streaks
						select c.symbol,
							c.candle_date,
							c.indicator_name,
							c.indicator_setting,
							c.win_1_atr,
							case when c.win_1_atr = 0
									and LAG(c.win_1_atr) over(partition by c.symbol,c.indicator_name,c.indicator_setting order by c.symbol,c.indicator_name,c.indicator_setting,c.candle_date) = 1
								then 1
								else 0
							end as streak
						from indicator_result c
						where c.indicator_signal = 1
							and c.candle_date >= $1
							and c.candle_date <= $2
							and c.finish_date <= $2
					) ns
					where ns.win_1_atr = 0
				) sn
      				group by sn.symbol, sn.indicator_name, sn.indicator_setting, sn.snum
			) rps
      			group by rps.symbol, rps.indicator_name, rps.indicator_setting
		) lose on lose.symbol = r.symbol
			and lose.indicator_name = r.indicator_name
			and lose.indicator_setting = r.indicator_setting
		left join
		(
			select symbol,
				indicator_name,
				indicator_setting,
				COUNT(win_1_atr) as total,
				sum(win_1_atr) as wins1,
				sum(win_2_atr) as wins2
			from indicator_result
			where candle_date >= $3
				and candle_date <= $4
				and indicator_signal = 1
				and finish_date <= $4
			group by symbol,
				indicator_name,
				indicator_setting
		) r1 on r1.symbol = r.symbol
			and r1.indicator_name = r.indicator_name
			and r1.indicator_setting = r.indicator_setting
	where r.candle_date >= $1
		and r.candle_date <= $2
		and r.indicator_signal = 1
		and r.finish_date <= $2
	group by r.symbol,
		r.indicator_name,
		r.indicator_setting,
		r1.total,
		r1.wins1,
		r1.wins2,
		lose.longest;
	
	DROP TABLE if exists strategy_result;
	create table strategy_result
	(
		strategy varchar(50),
		symbol varchar(10),
		indicator_name varchar(20),
		indicator_setting smallint,
		pre_total_signals bigint,
		pre_total_win1 bigint,
		pre_total_avg1 decimal(19, 9),
		pre_total_win2 bigint,
		pre_total_avg2 decimal(19, 9),
		pre_longest_lose_streak bigint,
		pre_roi decimal(19,9),
		post_total_signals bigint,
		post_total_win1 bigint,
		post_total_win2 bigint,
		post_roi decimal(19,9)
	);
	insert into strategy_result
	(
		strategy,
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	)
	-- simple roi desc, setting asc
	select 'SimpleRoiLowSetting' as strategy,
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	from
	(
		select *,
			rank() over(partition by t.symbol order by t.pre_roi desc, t.indicator_setting) as roi_rn
		from simulation_result t
		where t.pre_roi > 1
	) a
	where a.roi_rn = 1
	union all
	-- simple roi desc, setting desc
	select 'SimpleRoiHighSetting' as strategy,
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	from
	(
		select *,
			rank() over(partition by t.symbol order by t.pre_roi desc, t.indicator_setting desc) as roi_rn
		from simulation_result t
		where t.pre_roi > 1
	) a
	where a.roi_rn = 1
	union all
	-- 0 lose streak, Avg1 >= .8
	select 'NoLoseAvg1Gt80High' as strategy,
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	from
	(
		select *,
			rank() over(partition by t.symbol order by t.pre_roi desc, t.indicator_setting desc) as roi_rn
		from simulation_result t
		where t.pre_roi > 1
			and t.pre_longest_lose_streak = 0
			and t.pre_total_avg1 >= .8
	) a
	where a.roi_rn = 1
	union all
	-- winningest signals setting asc
	select 'WinningestSignalsLowSetting' as strategy,
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	from
	(
		select t1.*,
			rank() over(partition by t1.symbol order by t1.pre_roi desc, t1.indicator_setting) as roi_rn
		from simulation_result t1
			inner join
			(
				select *
				from
				(
					select a.symbol,
						indicator_name,
						sum(pass) as passes,
						rank() over(partition by a.symbol order by sum(pass) desc) as rn
					from
					(
						select *,
							case when pre_roi > 1 then 1
								else 0
							end as pass
						from simulation_result t
					) a
					group by symbol, indicator_name
				) x
				where x.rn = 1
			) b on b.symbol = t1.symbol
				and b.indicator_name = t1.indicator_name 
	) c
	where c.roi_rn=1
	union all
	-- winningest signals setting desc
	select 'WinningestSignalsHighSetting' as strategy,
		symbol,
		indicator_name,
		indicator_setting,
		pre_total_signals,
		pre_total_win1,
		pre_total_avg1,
		pre_total_win2,
		pre_total_avg2,
		pre_longest_lose_streak,
		pre_roi,
		post_total_signals,
		post_total_win1,
		post_total_win2,
		post_roi
	from
	(
		select t1.*,
			rank() over(partition by t1.symbol order by t1.pre_roi desc, t1.indicator_setting desc) as roi_rn
		from simulation_result t1
			inner join
			(
				select *
				from
				(
					select a.symbol,
						indicator_name,
						sum(pass) as passes,
						rank() over(partition by a.symbol order by sum(pass) desc) as rn
					from
					(
						select *,
							case when pre_roi > 1 then 1
								else 0
							end as pass
						from simulation_result t
					) a
					group by symbol, indicator_name
				) x
				where x.rn = 1
			) b on b.symbol = t1.symbol
				and b.indicator_name = t1.indicator_name 
	) c
	where c.roi_rn=1;
END;
$$
LANGUAGE plpgsql
;
