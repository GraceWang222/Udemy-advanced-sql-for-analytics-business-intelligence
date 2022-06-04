-- Teaching example:
-- step 1: find first website_pageview_id for relevent sessions

use mavenfuzzyfactory;
create temporary table first_pageviews_demo
select 
	p.website_session_id,
    min(p.website_pageview_id) as min_pageview_id
from website_pageviews p
join website_sessions s
using(website_session_id)
where s.created_at between '2014-01-01' and '2014-02-01'
group by website_session_id;
-- result should contain 14825 rows 

-- step 2: identifying the landing page of each session
create temporary table session_w_landing_page_demo
select
	f.website_session_id,
    p.pageview_url as landing_page
from first_pageviews_demo f
left join website_pageviews p
on f.min_pageview_id = p.website_pageview_id;

-- select * from session_w_landing_page_demo;
-- 每一个 sessionID 的首登页面类型;
-- drop table session_w_landing_page_demo;

-- step 3: counting pageviews for each session(ID), to identify 'bounces'
create temporary table bounced_sessions_only
select 
	sw.website_session_id,
    sw.landing_page,
    count(p.website_pageview_id) as count_of_pages_viewed
from session_w_landing_page_demo sw
left join website_pageviews p
on sw.website_session_id = p.website_session_id
group by 
	sw.website_session_id,
    sw.landing_page
having count(p.website_pageview_id) = 1;

-- select * from bounced_sessions_only;
-- 只有一个首登页面的 sessionID;
-- drop table bounced_sessions_only

-- step 4: summarizing by counting total sessions and bounced sessions
create temporary table final_table
select 
	x.landing_page, 
    x.website_session_id,
    y.website_session_id as bounced_website_session_id
from session_w_landing_page_demo x
left join bounced_sessions_only y
on x.website_session_id = y.website_session_id
order by x.website_session_id;

select 
	landing_page,
    count(website_session_id) as sessions,
    count(bounced_website_session_id) as bounced_sessions,
    concat(round(count(bounced_website_session_id)/count(website_session_id)*100,2) ,'%') as bounce_rate
from final_table  
group by landing_page
order by bounce_rate;

-- Practice assignment from PDF page76

-- step 1: identify the landing page info:
use mavenfuzzyfactory;
create temporary table landing_page_info
select 
	temp.website_session_id,
    temp.landing_id,
    wp.created_at,
    wp.pageview_url
from (select 
		website_session_id,
		min(website_pageview_id) as landing_id
	  from website_pageviews
	  where created_at < '2012-06-14'
	  group by website_session_id) as temp
left join website_pageviews wp
on temp.landing_id = wp.website_pageview_id
where wp.pageview_url = '/home';

select * from landing_page_info;


-- step 2: identify records about bounced sessions 
create temporary table bounced_sessions_info
select 
	lp.website_session_id,
    lp.pageview_url,
    count(wp.website_pageview_id) as cny_of_pageviews
from landing_page_info lp
left join website_pageviews wp
on lp.website_session_id = wp.website_session_id
group by lp.website_session_id,
		 lp.pageview_url
having count(wp.website_pageview_id) = 1;


-- step 3: summarize 
select 
	lp.pageview_url,
    count(lp.website_session_id) as sessions,
    count(bs.website_session_id) as bounced_sessions,
    count(bs.website_session_id)/count(lp.website_session_id) as bounce_rate
from landing_page_info lp
left join bounced_sessions_info bs
on lp.website_session_id = bs.website_session_id
group by lp.pageview_url
order by lp.pageview_url;















