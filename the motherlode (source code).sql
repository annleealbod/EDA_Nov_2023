-- The Motherlode
select case
    when (`swcmm`.`csa_name_mod` in ('Dallas-Fort Worth, TX-OK', 'Las Vegas-Henderson, NV', 'Salt Lake City-Provo-Orem, UT')) then swcmm.csa_name_mod
    else 'All Other Markets Combined'
    end as csa_name_mod2, c.id as company_id, c.name as company_name, sw.shifts_worked, ahc.adjusted_head_count, sw.shifts_worked / ahc.adjusted_head_count as fill_rate, ina.industry_name,
    avhc.average_head_count as avg_head_count, average_hourly_wage as avg_hourly_wage, asl.average_shift_lead as avg_shift_lead, ncr.total_net_commissionable_revenue_2023 as 2023_rev, adbs.avg_days_between_shifts, thc.total_head_count,
    yqcs.year_quarter_comp_start
from companies c
join postings p on c.id = p.company_id
join shifts s on p.id = s.posting_id
join shifts_with_csas_mv_mod swcmm on swcmm.shift_id = s.id
left join (
select aws.company_id,
       c.name as company_name,
       count(aws.worker_user_id) as shifts_worked
from analytic_worked_shifts aws
join companies c on aws.company_id = c.id
where date(aws.start_time) > '2023-01-01'
group by aws.company_id, c.name
     ) sw on c.id = sw.company_id
left join (
    select c.id as company_id,
       c.name as company_name,
       sum(ahc.adjusted_head_count) AS adjusted_head_count
from companies c
left join postings p on c.id = p.company_id
left join shifts s on p.id = s.posting_id
left join (
    select s.id AS shift_id,
    count(aws.worker_user_id) AS total_worked,
    case
     when count(aws.worker_user_id) > s.head_count
        then count(aws.worker_user_id)
     when count(aws.worker_user_id) <= s.head_count
        then s.head_count end AS adjusted_head_count
     from analytic_worked_shifts aws
     left join shifts s on aws.shift_id = s.id
     group by s.id
) ahc on s.id = ahc.shift_id
where s.start_time < now()
  and s.status != 6
and date(s.start_time) > '2023-01-01'
group by c.id
) ahc on ahc.company_id = sw.company_id
left join (
    select c.id as company_id,
    c.name as company_name,
    i.name as industry_name
from companies c
join industries i on c.industry_id = i.id
join postings p on c.id = p.company_id
join shifts s on p.id = s.posting_id
where date(s.start_time) > '2023-01-01'
group by c.id, c.name
) ina on ina.company_id = c.id
left join (
    SELECT
    company_id,
    AVG(TIMESTAMPDIFF(DAY, lag_shift_start_time, start_time)) AS avg_days_between_shifts
FROM (
    SELECT company_id,
             start_time,
             LAG(start_time) OVER (PARTITION BY company_id ORDER BY start_time) AS lag_shift_start_time
      FROM (
      select distinct shift_id, company_id, aws.start_time
        from analytic_worked_shifts aws
        where YEAR(start_time) = 2023
        group by company_id, shift_id) mini_table
      ) as lagged_data
GROUP BY  company_id
) adbs on adbs.company_id = c.id
left join (
    select c.id as company_id,
    c.name as company_name,
    avg(s.head_count) as average_head_count
from companies c
join postings p on c.id = p.company_id
join shifts s on p.id = s.posting_id
where date(s.start_time) > '2023-01-01'
and s.status != 6
group by c.id, c.name
) avhc on avhc.company_id = c.id
left join (
    select c.id as company_id,
    c.name as company_name,
    sum(s.head_count) as total_head_count
from companies c
join postings p on c.id = p.company_id
join shifts s on p.id = s.posting_id
where date(s.start_time) > '2023-01-01'
and s.status != 6
group by c.id, c.name
) thc on thc.company_id = c.id
left join (
    select c.id as company_id,
    c.name as company_name,
    avg(s.hourly_wage) as average_hourly_wage
from companies c
join postings p on c.id = p.company_id
join shifts s on p.id = s.posting_id
where date(s.start_time) > '2023-01-01'
and s.status != 6
group by c.id, c.name
) hw on hw.company_id = c.id
left join (
    select c.id as company_id,
    c.name as company_name,
    avg(dd.day_difference) as average_shift_lead
from companies c
join postings p on c.id = p.company_id
join shifts s on p.id = s.posting_id
left join (select s.id as shift_id, s.start_time, p.created_at, DATEDIFF(s.start_time, p.created_at) AS day_difference
from postings p
join shifts s on p.id = s.posting_id
group by s.id) dd on dd.shift_id = s.id
where date(s.start_time) > '2023-01-01'
group by c.id, c.name
) asl on asl.company_id = c.id
left join (
    SELECT company_id,
CONCAT(YEAR(company_start_time), 'Q', QUARTER(company_start_time)) AS year_quarter_comp_start
FROM (
    select aws.company_id, min(aws.start_time) as company_start_time
    from analytic_worked_shifts aws
    group by aws.company_id
     ) cst
ORDER BY year_quarter_comp_start
) yqcs on yqcs.company_id = c.id
left join (
    select p.company_id,
	c.name,
	round(sum(net_comm_rev),2) as total_net_commissionable_revenue_2023
from
(
select
	shift_id_rev,
	round(sum(net_commissionable_revenue)/100,2) as net_comm_rev
from
(
	select
	        `aa`.`shift_id` AS `shift_id_rev`,
			(case
	            when (`aa`.`action_type` in (7, 8, 17, 20)) then `aa`.`amount`
	            when (`aa`.`action_type` in (1, 12)) then (`aa`.`amount` * -(1))
	        end) AS `net_commissionable_revenue`
	 from
	        `accounting_actions` `aa`
) pt3a
group by shift_id_rev
) pt3
left join shifts s on pt3.shift_id_rev=s.id
left join postings p on s.posting_id=p.id
left join companies c on p.company_id=c.id
where s.start_time>'2022-12-31'
group by p.company_id
) ncr on ncr.company_id = c.id
where c.id != 3662
group by csa_name_mod2, c.id;
