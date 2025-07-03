--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dim_branch; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_branch (
    sk_branch double precision,
    branch_id character varying(255),
    branch_name character varying(255),
    city character varying(255),
    province character varying(255)
);


ALTER TABLE public.dim_branch OWNER TO postgres;

--
-- Name: fact_assignment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fact_assignment (
    sk_assignment double precision,
    sk_employee integer,
    sk_project integer,
    sk_task integer,
    sk_branch integer,
    sk_time bigint,
    planned_hours numeric(12,2),
    actual_hours numeric(12,2),
    utilization_rate double precision,
    efficiency_score double precision,
    assignment_cost integer,
    assignment_status character varying(255)
);


ALTER TABLE public.fact_assignment OWNER TO postgres;

--
-- Name: branch_workload_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.branch_workload_summary AS
 SELECT b.branch_name,
    sum(a.planned_hours) AS total_planned_hours,
    sum(a.actual_hours) AS total_actual_hours,
    sum(a.assignment_cost) AS total_cost
   FROM (public.fact_assignment a
     JOIN public.dim_branch b ON ((a.sk_branch = (b.sk_branch)::integer)))
  GROUP BY b.branch_name
  ORDER BY b.branch_name;


ALTER VIEW public.branch_workload_summary OWNER TO postgres;

--
-- Name: dim_employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_employee (
    sk_employee double precision,
    employee_id character varying(255),
    full_name text,
    hire_date date,
    tenure integer,
    department character varying(255),
    job_title character varying(255),
    skill_level character varying(255),
    specialization character varying(255),
    hourly_cost_rate numeric(12,2)
);


ALTER TABLE public.dim_employee OWNER TO postgres;

--
-- Name: classification_efficiency; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.classification_efficiency AS
 SELECT a.sk_employee,
    e.full_name,
    max(a.efficiency_score) AS max_efficiency_score,
        CASE
            WHEN (max(a.efficiency_score) >= (80)::double precision) THEN 'Efficient'::text
            WHEN ((max(a.efficiency_score) >= (50)::double precision) AND (max(a.efficiency_score) <= (79)::double precision)) THEN 'Moderate'::text
            ELSE 'Inefficient'::text
        END AS efficiency_classification
   FROM (public.fact_assignment a
     JOIN public.dim_employee e ON (((a.sk_employee)::double precision = e.sk_employee)))
  GROUP BY a.sk_employee, e.full_name;


ALTER VIEW public.classification_efficiency OWNER TO postgres;

--
-- Name: cluster_workload; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.cluster_workload AS
 WITH workload AS (
         SELECT a.sk_employee,
            e.full_name,
            sum(a.actual_hours) AS total_hours
           FROM (public.fact_assignment a
             JOIN public.dim_employee e ON (((a.sk_employee)::double precision = e.sk_employee)))
          GROUP BY a.sk_employee, e.full_name
        )
 SELECT sk_employee,
    full_name,
    total_hours,
        CASE
            WHEN (total_hours < (100)::numeric) THEN 'Low Workload'::text
            WHEN ((total_hours >= (100)::numeric) AND (total_hours <= (200)::numeric)) THEN 'Medium Workload'::text
            ELSE 'High Workload'::text
        END AS workload_cluster
   FROM workload;


ALTER VIEW public.cluster_workload OWNER TO postgres;

--
-- Name: dim_project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_project (
    sk_project double precision,
    project_id character varying(255),
    project_name character varying(255),
    start_date date,
    end_date date,
    project_duration double precision,
    project_type character varying(255),
    project_budget integer,
    budget_consumed integer,
    priority_level character varying(255)
);


ALTER TABLE public.dim_project OWNER TO postgres;

--
-- Name: dim_task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_task (
    sk_task double precision,
    task_id character varying(255),
    task_name character varying(255),
    task_category character varying(255),
    required_skill character varying(255),
    estimated_hours numeric(12,2),
    complexity_level character varying(255)
);


ALTER TABLE public.dim_task OWNER TO postgres;

--
-- Name: dim_time; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_time (
    sk_time bigint,
    work_date date,
    hari double precision,
    bulan double precision,
    kuartal text,
    tahun double precision
);


ALTER TABLE public.dim_time OWNER TO postgres;

--
-- Name: employee_monthly_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_monthly_performance AS
 SELECT e.sk_employee,
    e.full_name,
    ti.tahun,
    ti.bulan,
    sum(a.actual_hours) AS total_actual_hours
   FROM ((public.fact_assignment a
     JOIN public.dim_employee e ON (((a.sk_employee)::double precision = e.sk_employee)))
     JOIN public.dim_time ti ON ((a.sk_time = ti.sk_time)))
  GROUP BY e.sk_employee, e.full_name, ti.tahun, ti.bulan
  ORDER BY e.sk_employee, ti.tahun, ti.bulan;


ALTER VIEW public.employee_monthly_performance OWNER TO postgres;

--
-- Name: employee_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_summary AS
 SELECT e.sk_employee,
    e.full_name,
    sum(a.planned_hours) AS total_planned_hours,
    sum(a.actual_hours) AS total_actual_hours,
    sum(a.assignment_cost) AS total_assignment_cost
   FROM (public.fact_assignment a
     JOIN public.dim_employee e ON (((a.sk_employee)::double precision = e.sk_employee)))
  GROUP BY e.sk_employee, e.full_name
  ORDER BY (sum(a.actual_hours)) DESC;


ALTER VIEW public.employee_summary OWNER TO postgres;

--
-- Name: employee_workload_cluster; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_workload_cluster AS
 SELECT e.sk_employee,
    e.full_name,
    sum(a.actual_hours) AS total_actual_hours,
    sum(a.assignment_cost) AS total_cost,
        CASE
            WHEN (sum(a.actual_hours) > (160)::numeric) THEN 'High Workload'::text
            WHEN ((sum(a.actual_hours) >= (80)::numeric) AND (sum(a.actual_hours) <= (160)::numeric)) THEN 'Medium Workload'::text
            ELSE 'Low Workload'::text
        END AS workload_cluster
   FROM (public.fact_assignment a
     JOIN public.dim_employee e ON (((a.sk_employee)::double precision = e.sk_employee)))
  GROUP BY e.sk_employee, e.full_name;


ALTER VIEW public.employee_workload_cluster OWNER TO postgres;

--
-- Name: fact_timesheet; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fact_timesheet (
    sk_timesheet double precision,
    sk_employee double precision,
    sk_project double precision,
    sk_task double precision,
    sk_cabang double precision,
    sk_time bigint,
    hours_worked numeric(12,2),
    work_type character varying(255),
    approval_status character varying(255),
    billable_hours numeric(18,2),
    non_billable_hours numeric(18,2),
    complete_percentage integer,
    schedule_variance numeric(18,2),
    cost_variance numeric(18,2),
    resource_allocated integer
);


ALTER TABLE public.fact_timesheet OWNER TO postgres;

--
-- Name: forecast_monthly_hours; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.forecast_monthly_hours AS
 SELECT e.sk_employee,
    e.full_name,
    make_date((ti.tahun)::integer, (ti.bulan)::integer, 1) AS date,
    sum(a.actual_hours) AS total_actual_hours,
    avg(sum(a.actual_hours)) OVER (PARTITION BY e.sk_employee ORDER BY (make_date((ti.tahun)::integer, (ti.bulan)::integer, 1)) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_months
   FROM ((public.fact_assignment a
     JOIN public.dim_employee e ON (((a.sk_employee)::double precision = e.sk_employee)))
     JOIN public.dim_time ti ON ((a.sk_time = ti.sk_time)))
  GROUP BY e.sk_employee, e.full_name, ti.tahun, ti.bulan
  ORDER BY e.sk_employee, (make_date((ti.tahun)::integer, (ti.bulan)::integer, 1));


ALTER VIEW public.forecast_monthly_hours OWNER TO postgres;

--
-- Name: project_assignment_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.project_assignment_status AS
 SELECT p.sk_project,
    p.project_name,
    a.assignment_status,
    count(*) AS num_assignments
   FROM (public.fact_assignment a
     JOIN public.dim_project p ON (((a.sk_project)::double precision = p.sk_project)))
  GROUP BY p.sk_project, p.project_name, a.assignment_status
  ORDER BY p.project_name;


ALTER VIEW public.project_assignment_status OWNER TO postgres;

--
-- Name: project_completion_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.project_completion_status AS
 SELECT p.sk_project,
    p.project_name,
    avg(ts.complete_percentage) AS avg_completion,
        CASE
            WHEN (avg(ts.complete_percentage) >= (50)::numeric) THEN 'On Track'::text
            WHEN ((avg(ts.complete_percentage) >= (30)::numeric) AND (avg(ts.complete_percentage) <= 49.99)) THEN 'At Risk'::text
            ELSE 'Delayed'::text
        END AS project_status
   FROM (public.dim_project p
     JOIN public.fact_timesheet ts ON ((p.sk_project = ts.sk_project)))
  GROUP BY p.sk_project, p.project_name;


ALTER VIEW public.project_completion_status OWNER TO postgres;

--
-- Name: project_completion_status_standardized; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.project_completion_status_standardized AS
 WITH avg_completion_per_project AS (
         SELECT p.sk_project,
            p.project_name,
            avg(ts.complete_percentage) AS avg_completion
           FROM (public.dim_project p
             JOIN public.fact_timesheet ts ON ((p.sk_project = ts.sk_project)))
          GROUP BY p.sk_project, p.project_name
        ), stats AS (
         SELECT avg(avg_completion_per_project.avg_completion) AS mean_completion,
            stddev_pop(avg_completion_per_project.avg_completion) AS stddev_completion
           FROM avg_completion_per_project
        ), final AS (
         SELECT ac.sk_project,
            ac.project_name,
            ac.avg_completion,
            ((ac.avg_completion - s.mean_completion) / NULLIF(s.stddev_completion, (0)::numeric)) AS z_score
           FROM (avg_completion_per_project ac
             CROSS JOIN stats s)
        )
 SELECT sk_project,
    project_name,
    avg_completion,
    z_score,
        CASE
            WHEN (z_score >= (0)::numeric) THEN 'On Track'::text
            WHEN (z_score >= ('-1'::integer)::numeric) THEN 'At Risk'::text
            ELSE 'Delayed'::text
        END AS project_status
   FROM final;


ALTER VIEW public.project_completion_status_standardized OWNER TO postgres;

--
-- Name: quarterly_project_revenue; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.quarterly_project_revenue AS
 SELECT p.sk_project,
    p.project_name,
    ti.kuartal,
    ti.tahun,
    sum(a.assignment_cost) AS total_cost
   FROM ((public.fact_assignment a
     JOIN public.dim_project p ON (((a.sk_project)::double precision = p.sk_project)))
     JOIN public.dim_time ti ON ((a.sk_time = ti.sk_time)))
  GROUP BY p.sk_project, p.project_name, ti.tahun, ti.kuartal
  ORDER BY p.sk_project, ti.tahun, ti.kuartal;


ALTER VIEW public.quarterly_project_revenue OWNER TO postgres;

--
-- Data for Name: dim_branch; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_branch (sk_branch, branch_id, branch_name, city, province) FROM stdin;
1	BRN0001	PT EXODUS Jakarta 01	Jakarta	DKI Jakarta
2	BRN0002	PT EXODUS Surabaya 01	Surabaya	Jawa Timur
3	BRN0003	PT EXODUS Bandung 01	Bandung	Jawa Barat
4	BRN0004	PT EXODUS Medan 01	Medan	Sumatera Utara
5	BRN0005	PT EXODUS Semarang 01	Semarang	Jawa Tengah
6	BRN0006	PT EXODUS Makassar 01	Makassar	Sulawesi Selatan
7	BRN0007	PT EXODUS Palembang 01	Palembang	Sumatera Selatan
8	BRN0008	PT EXODUS Tangerang 01	Tangerang	Banten
9	BRN0009	PT EXODUS Depok 01	Depok	Jawa Barat
10	BRN0010	PT EXODUS Bekasi 01	Bekasi	Jawa Barat
11	BRN0011	PT EXODUS Yogyakarta 01	Yogyakarta	DI Yogyakarta
12	BRN0012	PT EXODUS Malang 01	Malang	Jawa Timur
\.


--
-- Data for Name: dim_employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_employee (sk_employee, employee_id, full_name, hire_date, tenure, department, job_title, skill_level, specialization, hourly_cost_rate) FROM stdin;
1	EMP0001	Sari Kusumo	2017-08-10	93	IT	Software Developer	Menengah	Cloud Computing	65.62
2	EMP0002	Kunthara Prasasta	2019-03-11	74	IT	Database Administrator	Ahli	Web Development	52.22
3	EMP0003	Damu Wastuti	2023-05-01	24	IT	System Analyst	Pemula	Mobile Development	89.29
4	EMP0004	Hafshah Irawan	2022-02-16	39	Operations	Supply Chain Coordinator	Ahli	Quality Management	72.41
5	EMP0005	Atma Dabukke	2018-02-26	87	IT	System Analyst	Lanjutan	Data Engineering	69.45
6	EMP0006	Jaka Mayasari	2022-03-22	38	HR	HR Business Partner	Pemula	Talent Acquisition	59.00
7	EMP0007	Iriana Napitupulu	2023-02-18	27	Finance	Tax Specialist	Lanjutan	Treasury	89.39
8	EMP0008	Hafshah Andriani	2019-03-03	74	Marketing	Social Media Manager	Ahli	Digital Marketing	38.94
9	EMP0009	Maria Setiawan	2023-11-18	18	Finance	Audit Manager	Menengah	Tax Management	83.75
10	EMP0010	Adinata Manullang	2022-12-28	29	IT	System Analyst	Pemula	Cloud Computing	109.87
11	EMP0011	Maman Setiawan	2018-08-26	81	IT	IT Support	Ahli	Cloud Computing	94.50
12	EMP0012	Muni Jailani	2018-02-23	87	Finance	Accountant	Lanjutan	Tax Management	56.52
13	EMP0013	Dagel Tamba	2024-03-08	14	Finance	Financial Analyst	Menengah	Treasury	74.38
14	EMP0014	Nova Saptono	2023-11-11	18	HR	Recruiter	Ahli	Learning & Development	53.50
15	EMP0015	Vega Nasyiah	2018-05-28	84	Operations	Process Analyst	Pemula	Supply Chain	52.60
16	EMP0016	Praba Hutapea	2021-10-27	43	IT	DevOps Engineer	Lanjutan	Data Engineering	54.63
17	EMP0017	Restu Safitri	2024-06-27	11	Operations	Quality Assurance	Ahli	Quality Management	61.76
18	EMP0018	Nyoman Permata	2018-12-11	77	Marketing	Content Creator	Menengah	Brand Management	47.33
19	EMP0019	Cahyono Gunawan	2022-09-11	32	Operations	Project Coordinator	Ahli	Supply Chain	89.38
20	EMP0020	Labuh Hutapea	2024-03-31	13	Marketing	Brand Manager	Menengah	Content Strategy	60.48
21	EMP0021	Damar Wibowo	2019-08-18	69	IT	Software Developer	Menengah	Web Development	93.92
22	EMP0022	Rahmi Utama	2018-09-16	80	Marketing	Social Media Manager	Ahli	Digital Marketing	54.08
23	EMP0023	Nyana Pranowo	2022-10-07	31	Marketing	Social Media Manager	Pemula	Brand Management	69.01
24	EMP0024	Wani Yuliarti	2017-12-23	89	IT	Database Administrator	Lanjutan	Cloud Computing	57.81
25	EMP0025	Rahmi Narpati	2021-09-05	44	Marketing	Content Creator	Pemula	Performance Marketing	82.69
26	EMP0026	Jindra Marpaung	2021-02-07	51	Finance	Audit Manager	Pemula	Cost Accounting	92.88
27	EMP0027	Kayun Uyainah	2022-11-29	30	Finance	Audit Manager	Menengah	Treasury	53.41
28	EMP0028	Ismail Simbolon	2024-02-23	15	HR	Training Specialist	Pemula	Payroll	69.95
29	EMP0029	Balidin Pradana	2023-12-24	17	Marketing	Digital Marketing Specialist	Lanjutan	Digital Marketing	78.94
30	EMP0030	Laswi Wacana	2019-07-20	70	Finance	Accountant	Menengah	Financial Planning	93.29
31	EMP0031	Indra Purnawati	2024-05-31	11	IT	Software Developer	Pemula	Data Engineering	118.46
32	EMP0032	Lasmono Prabowo	2022-08-25	33	Operations	Process Analyst	Ahli	Quality Management	92.08
33	EMP0033	Prima Yuniar	2021-01-28	52	HR	HR Business Partner	Ahli	Payroll	88.22
34	EMP0034	Karta Mandala	2019-05-19	72	Operations	Process Analyst	Ahli	Supply Chain	94.73
35	EMP0035	Iriana Nasyiah	2019-07-05	70	Finance	Budget Analyst	Ahli	Treasury	51.66
36	EMP0036	Laila Aryani	2024-08-02	9	HR	HR Generalist	Pemula	Performance Management	69.42
37	EMP0037	Raditya Tarihoran	2019-02-28	75	HR	Training Specialist	Pemula	Employee Relations	43.55
38	EMP0038	Enteng Melani	2021-05-09	48	IT	System Analyst	Pemula	Web Development	110.17
39	EMP0039	Bakiono Kusumo	2018-08-18	81	IT	Database Administrator	Lanjutan	Mobile Development	96.83
40	EMP0040	Galuh Zulaika	2020-10-13	55	HR	Training Specialist	Ahli	Employee Relations	52.15
41	EMP0041	Cagak Winarno	2020-06-16	59	Marketing	SEO Analyst	Pemula	Content Strategy	39.85
42	EMP0042	Waluyo Nuraini	2019-06-02	71	Marketing	Brand Manager	Ahli	Performance Marketing	58.35
43	EMP0043	Intan Anggriawan	2022-11-06	30	IT	Software Developer	Ahli	Web Development	100.97
44	EMP0044	Dartono Zulaika	2024-06-25	11	IT	System Analyst	Menengah	Mobile Development	87.54
45	EMP0045	Kasusra Yuniar	2020-02-16	63	HR	Compensation Analyst	Lanjutan	Employee Relations	63.13
46	EMP0046	Langgeng Fujiati	2018-09-02	80	IT	IT Support	Pemula	Network Security	53.54
47	EMP0047	Adiarja Saptono	2025-03-06	2	Operations	Operations Manager	Menengah	Process Improvement	49.15
48	EMP0048	Garda Mayasari	2024-09-14	8	Marketing	SEO Analyst	Ahli	Content Strategy	80.12
49	EMP0049	Queen Salahudin	2024-02-20	15	HR	Compensation Analyst	Ahli	Talent Acquisition	53.26
50	EMP0050	Cinthia Sudiati	2018-12-31	76	Marketing	Brand Manager	Ahli	Performance Marketing	42.74
51	EMP0051	Pangeran Marpaung	2021-09-20	44	Finance	Accountant	Pemula	Financial Planning	86.14
52	EMP0052	Febi Adriansyah	2022-03-13	38	IT	Software Developer	Ahli	Network Security	85.20
53	EMP0053	Aisyah Budiyanto	2018-04-20	85	Operations	Process Analyst	Pemula	Process Improvement	86.82
54	EMP0054	Olga Samosir	2019-04-28	73	IT	Database Administrator	Menengah	Web Development	78.26
55	EMP0055	Jaya Purnawati	2024-12-24	5	Operations	Process Analyst	Pemula	Customer Service	74.07
56	EMP0056	Cawisono Laksita	2023-12-07	17	Marketing	Social Media Manager	Lanjutan	Creative Design	81.74
57	EMP0057	Farah Mahendra	2018-06-08	83	HR	HR Business Partner	Lanjutan	Employee Relations	59.79
58	EMP0058	Wasis Pudjiastuti	2018-09-23	80	Finance	Budget Analyst	Pemula	Tax Management	45.51
59	EMP0059	Elvina Sudiati	2020-10-15	55	Operations	Project Coordinator	Pemula	Process Improvement	69.57
60	EMP0060	Indra Namaga	2023-06-13	23	Operations	Quality Assurance	Lanjutan	Quality Management	88.45
61	EMP0061	Yance Pangestu	2023-02-09	27	HR	HR Business Partner	Menengah	Performance Management	61.91
62	EMP0062	Raditya Winarsih	2022-08-09	33	Operations	Quality Assurance	Pemula	Customer Service	76.73
63	EMP0063	Taufik Maryati	2021-01-06	52	Operations	Quality Assurance	Menengah	Process Improvement	54.55
64	EMP0064	Jumari Prasetyo	2017-12-02	89	IT	Database Administrator	Lanjutan	Mobile Development	69.72
65	EMP0065	Artanto Rahmawati	2021-11-02	42	HR	HR Business Partner	Lanjutan	Employee Relations	65.27
66	EMP0066	Lintang Prasetya	2017-06-19	95	Finance	Financial Analyst	Ahli	Financial Planning	90.61
67	EMP0067	Rina Halim	2019-03-28	74	IT	Software Developer	Menengah	Cloud Computing	94.60
68	EMP0068	Atma Sitompul	2017-12-21	89	Finance	Accountant	Ahli	Internal Audit	75.85
69	EMP0069	Jaswadi Setiawan	2022-10-04	31	IT	Software Developer	Pemula	Mobile Development	108.42
70	EMP0070	Ikhsan Namaga	2018-06-19	83	Operations	Project Coordinator	Ahli	Quality Management	47.01
71	EMP0071	Kamila Permata	2021-03-09	50	Finance	Tax Specialist	Lanjutan	Financial Planning	56.55
72	EMP0072	Warsita Wasita	2018-12-06	77	HR	HR Generalist	Ahli	Performance Management	88.69
73	EMP0073	Dagel Wahyuni	2020-11-08	54	HR	Recruiter	Menengah	Employee Relations	84.07
74	EMP0074	Slamet Zulkarnain	2021-02-21	51	IT	System Analyst	Ahli	Cloud Computing	106.16
75	EMP0075	Balangga Wulandari	2022-08-19	33	HR	HR Business Partner	Pemula	Employee Relations	59.13
76	EMP0076	Safina Januar	2017-11-22	90	IT	IT Support	Menengah	Mobile Development	107.16
77	EMP0077	Mustika Kurniawan	2019-05-25	72	Marketing	Brand Manager	Menengah	Brand Management	46.15
78	EMP0078	Harjasa Nasyiah	2020-12-29	53	HR	Compensation Analyst	Lanjutan	Performance Management	83.22
79	EMP0079	Surya Najmudin	2019-08-20	69	Finance	Tax Specialist	Ahli	Treasury	82.37
80	EMP0080	Jamil Hutagalung	2020-12-13	53	Operations	Quality Assurance	Pemula	Process Improvement	88.24
81	EMP0081	Humaira Januar	2017-10-23	91	Finance	Accountant	Lanjutan	Treasury	47.10
82	EMP0082	Gina Budiman	2025-02-26	3	Operations	Supply Chain Coordinator	Lanjutan	Supply Chain	64.00
83	EMP0083	Jasmani Marbun	2020-08-28	57	Operations	Operations Manager	Menengah	Project Management	54.01
84	EMP0084	Yono Prabowo	2024-04-27	13	Marketing	Digital Marketing Specialist	Menengah	Creative Design	53.21
85	EMP0085	Banara Marbun	2020-06-08	59	IT	DevOps Engineer	Lanjutan	Network Security	96.44
86	EMP0086	Purwadi Saptono	2024-10-25	7	IT	DevOps Engineer	Lanjutan	Network Security	96.68
87	EMP0087	Upik Suwarno	2020-10-15	55	Finance	Budget Analyst	Menengah	Tax Management	55.55
88	EMP0088	Ida Wijayanti	2023-02-25	27	Marketing	Content Creator	Lanjutan	Creative Design	55.30
89	EMP0089	Galak Nainggolan	2019-10-12	67	IT	DevOps Engineer	Menengah	Cloud Computing	80.09
90	EMP0090	Bambang Prastuti	2023-04-17	25	Operations	Project Coordinator	Ahli	Supply Chain	64.30
91	EMP0091	Banawi Sihotang	2017-11-11	90	HR	Training Specialist	Menengah	Learning & Development	72.94
92	EMP0092	Laila Kuswandari	2021-06-05	47	Finance	Audit Manager	Lanjutan	Treasury	50.14
93	EMP0093	Febi Manullang	2017-11-11	90	HR	HR Business Partner	Menengah	Employee Relations	47.37
94	EMP0094	Ciaobella Hutapea	2024-03-19	14	IT	System Analyst	Pemula	Data Engineering	81.88
95	EMP0095	Cahyo Riyanti	2017-12-13	89	Operations	Process Analyst	Ahli	Project Management	61.98
96	EMP0096	Jarwadi Waskita	2018-05-14	84	HR	HR Generalist	Ahli	Talent Acquisition	50.94
97	EMP0097	Kamaria Prayoga	2022-01-14	40	Operations	Supply Chain Coordinator	Menengah	Process Improvement	90.46
98	EMP0098	Bahuwirya Safitri	2018-01-23	88	IT	IT Support	Ahli	Mobile Development	96.73
99	EMP0099	Tira Padmasari	2021-12-05	41	Operations	Project Coordinator	Ahli	Supply Chain	73.70
100	EMP0100	Laswi Rajata	2019-01-15	76	Operations	Supply Chain Coordinator	Ahli	Customer Service	89.35
101	EMP0101	Lutfan Permadi	2019-07-13	70	Marketing	SEO Analyst	Menengah	Brand Management	76.99
102	EMP0102	Eluh Winarsih	2022-07-27	34	Finance	Audit Manager	Menengah	Internal Audit	60.10
103	EMP0103	Vinsen Sihotang	2024-11-01	6	IT	DevOps Engineer	Lanjutan	Mobile Development	73.51
104	EMP0104	Cakrabuana Anggriawan	2021-01-26	52	Operations	Operations Manager	Menengah	Quality Management	52.72
105	EMP0105	Janet Januar	2017-12-28	89	HR	Recruiter	Ahli	Talent Acquisition	60.38
106	EMP0106	Irsad Mayasari	2019-07-12	70	Operations	Supply Chain Coordinator	Pemula	Project Management	51.38
107	EMP0107	Nalar Hidayat	2024-06-09	11	Marketing	SEO Analyst	Pemula	Creative Design	77.84
108	EMP0108	Okta Suryono	2018-09-01	80	Operations	Supply Chain Coordinator	Pemula	Project Management	91.85
109	EMP0109	Hesti Sihombing	2022-04-19	37	Finance	Budget Analyst	Menengah	Internal Audit	71.85
110	EMP0110	Silvia Nuraini	2017-06-20	95	Finance	Budget Analyst	Pemula	Internal Audit	66.39
111	EMP0111	Irma Salahudin	2024-11-09	6	Marketing	Content Creator	Menengah	Performance Marketing	84.04
112	EMP0112	Daniswara Mansur	2019-07-10	70	Operations	Operations Manager	Pemula	Project Management	44.62
113	EMP0113	Dariati Puspasari	2018-08-26	81	Marketing	Content Creator	Menengah	Performance Marketing	37.51
114	EMP0114	Kardi Suartini	2019-02-03	75	Marketing	Brand Manager	Ahli	Content Strategy	51.34
115	EMP0115	Mahfud Putra	2022-11-27	30	Marketing	Brand Manager	Lanjutan	Performance Marketing	76.75
116	EMP0116	Karsana Mayasari	2021-04-25	49	Marketing	Digital Marketing Specialist	Pemula	Creative Design	85.00
117	EMP0117	Baktiono Iswahyudi	2022-06-24	35	Finance	Accountant	Pemula	Financial Planning	86.48
118	EMP0118	Kadir Gunawan	2017-06-08	95	HR	Recruiter	Menengah	Talent Acquisition	51.93
119	EMP0119	Elon Uyainah	2025-03-29	2	Marketing	Digital Marketing Specialist	Menengah	Creative Design	58.25
120	EMP0120	Gaman Handayani	2021-10-26	43	Finance	Tax Specialist	Pemula	Cost Accounting	87.78
121	EMP0121	Sabar Purwanti	2017-06-26	95	HR	HR Business Partner	Pemula	Talent Acquisition	86.44
122	EMP0122	Cakrawangsa Maryadi	2021-10-08	43	Operations	Supply Chain Coordinator	Menengah	Project Management	44.18
123	EMP0123	Okta Padmasari	2021-10-28	43	HR	HR Generalist	Pemula	Performance Management	79.81
124	EMP0124	Satya Mahendra	2017-09-28	92	Operations	Operations Manager	Ahli	Supply Chain	76.38
125	EMP0125	Omar Gunarto	2024-08-05	9	IT	Database Administrator	Pemula	Cloud Computing	109.47
126	EMP0126	Imam Zulaika	2019-05-27	72	Marketing	Digital Marketing Specialist	Lanjutan	Performance Marketing	66.78
127	EMP0127	Danang Thamrin	2023-08-24	21	Marketing	Content Creator	Menengah	Performance Marketing	71.69
128	EMP0128	Rahmat Safitri	2023-05-27	24	Finance	Audit Manager	Ahli	Treasury	70.57
129	EMP0129	Jasmani Marpaung	2025-03-19	2	Operations	Quality Assurance	Menengah	Supply Chain	85.69
130	EMP0130	Garang Zulkarnain	2017-08-09	93	IT	DevOps Engineer	Menengah	Data Engineering	102.53
131	EMP0131	Mulya Zulkarnain	2023-10-28	19	Operations	Project Coordinator	Lanjutan	Project Management	41.58
132	EMP0132	Jamal Santoso	2018-09-06	80	Finance	Accountant	Menengah	Internal Audit	64.52
133	EMP0133	Darijan Wibowo	2024-05-19	12	Finance	Tax Specialist	Lanjutan	Tax Management	75.57
134	EMP0134	Wage Prasetya	2019-01-01	76	Operations	Process Analyst	Menengah	Process Improvement	79.60
135	EMP0135	Viman Tampubolon	2019-11-06	66	Marketing	Social Media Manager	Ahli	Content Strategy	67.30
136	EMP0136	Jaga Prasetyo	2017-08-06	93	Marketing	SEO Analyst	Pemula	Digital Marketing	49.71
137	EMP0137	Harsana Wacana	2020-01-12	64	Marketing	Content Creator	Lanjutan	Brand Management	58.66
138	EMP0138	Cahyono Setiawan	2020-03-19	62	Operations	Quality Assurance	Lanjutan	Project Management	59.35
139	EMP0139	Cici Wacana	2022-11-03	30	Marketing	Brand Manager	Lanjutan	Brand Management	46.53
140	EMP0140	Gasti Sitompul	2024-12-01	5	HR	HR Business Partner	Menengah	Talent Acquisition	49.58
141	EMP0141	Daru Rajata	2018-11-01	78	Marketing	Brand Manager	Lanjutan	Creative Design	84.03
142	EMP0142	Karta Firgantoro	2018-04-10	85	HR	HR Business Partner	Lanjutan	Employee Relations	48.97
143	EMP0143	Taswir Situmorang	2023-03-27	26	IT	Database Administrator	Lanjutan	Mobile Development	53.19
144	EMP0144	Lutfan Fujiati	2022-04-03	37	IT	Database Administrator	Menengah	Cloud Computing	94.65
145	EMP0145	Calista Latupono	2020-06-27	59	Marketing	Digital Marketing Specialist	Lanjutan	Digital Marketing	58.47
146	EMP0146	Keisha Nainggolan	2019-06-12	71	Marketing	Brand Manager	Pemula	Content Strategy	47.62
147	EMP0147	Teddy Adriansyah	2021-07-25	46	Marketing	Digital Marketing Specialist	Ahli	Digital Marketing	59.59
148	EMP0148	Genta Winarsih	2018-12-25	77	Operations	Operations Manager	Menengah	Quality Management	84.61
149	EMP0149	Setya Hidayat	2024-12-29	5	Finance	Financial Analyst	Pemula	Cost Accounting	75.69
150	EMP0150	Mitra Oktaviani	2019-12-01	65	Marketing	Social Media Manager	Menengah	Creative Design	73.78
151	EMP0151	Drajat Salahudin	2021-06-18	47	Marketing	SEO Analyst	Lanjutan	Performance Marketing	78.01
152	EMP0152	Unjani Wasita	2020-01-06	64	Marketing	Brand Manager	Pemula	Creative Design	65.48
153	EMP0153	Zamira Sihombing	2021-11-03	42	IT	System Analyst	Lanjutan	Mobile Development	96.23
154	EMP0154	Harjo Andriani	2022-09-22	32	HR	Recruiter	Pemula	Employee Relations	47.83
155	EMP0155	Prabu Wastuti	2023-05-23	24	Marketing	SEO Analyst	Ahli	Creative Design	49.56
156	EMP0156	Gantar Susanti	2021-12-16	41	HR	HR Business Partner	Ahli	Performance Management	43.56
157	EMP0157	Rosman Pudjiastuti	2024-01-28	16	HR	HR Business Partner	Menengah	Payroll	61.26
158	EMP0158	Lulut Suwarno	2019-02-01	75	Operations	Process Analyst	Lanjutan	Quality Management	85.46
159	EMP0159	Kayla Sudiati	2022-08-23	33	IT	Software Developer	Lanjutan	Mobile Development	91.65
160	EMP0160	Wadi Handayani	2020-12-10	53	Operations	Quality Assurance	Pemula	Project Management	65.78
161	EMP0161	Irsad Melani	2021-03-11	50	Finance	Budget Analyst	Ahli	Tax Management	69.08
162	EMP0162	Gandi Wahyuni	2018-01-31	87	Operations	Operations Manager	Lanjutan	Project Management	73.20
163	EMP0163	Diah Wijayanti	2022-06-20	35	IT	Software Developer	Pemula	Mobile Development	119.97
164	EMP0164	Mumpuni Iswahyudi	2023-12-14	17	Finance	Audit Manager	Menengah	Financial Planning	70.88
165	EMP0165	Jarwadi Wulandari	2019-11-21	66	Marketing	Brand Manager	Ahli	Content Strategy	66.74
166	EMP0166	Hasta Maulana	2017-08-08	93	Marketing	Digital Marketing Specialist	Lanjutan	Performance Marketing	55.42
167	EMP0167	Jindra Kusmawati	2022-04-18	37	Finance	Financial Analyst	Lanjutan	Cost Accounting	67.64
168	EMP0168	Cakrabuana Hasanah	2020-09-20	56	Marketing	Brand Manager	Pemula	Performance Marketing	57.74
169	EMP0169	Rini Permata	2018-12-17	77	Finance	Tax Specialist	Pemula	Tax Management	98.36
170	EMP0170	Zamira Winarno	2021-05-12	48	Marketing	Social Media Manager	Ahli	Digital Marketing	55.66
171	EMP0171	Jinawi Maulana	2022-08-27	33	HR	Training Specialist	Ahli	Performance Management	71.27
172	EMP0172	Adikara Kurniawan	2023-08-19	21	IT	System Analyst	Menengah	Cloud Computing	114.94
173	EMP0173	Ismail Nugroho	2023-11-02	18	Marketing	SEO Analyst	Pemula	Digital Marketing	83.66
174	EMP0174	Zulaikha Maryati	2021-02-13	51	Operations	Process Analyst	Lanjutan	Quality Management	70.30
175	EMP0175	Ifa Prayoga	2024-09-28	8	Operations	Supply Chain Coordinator	Menengah	Process Improvement	94.57
176	EMP0176	Dimaz Hasanah	2018-06-22	83	IT	IT Support	Menengah	Web Development	84.89
177	EMP0177	Wisnu Widiastuti	2021-08-27	45	Finance	Audit Manager	Ahli	Tax Management	90.91
178	EMP0178	Ina Riyanti	2019-12-11	65	Marketing	Content Creator	Menengah	Performance Marketing	54.18
179	EMP0179	Timbul Suryatmi	2023-12-04	17	Operations	Project Coordinator	Pemula	Quality Management	55.19
180	EMP0180	Clara Aryani	2024-01-19	16	Marketing	Brand Manager	Lanjutan	Creative Design	76.03
\.


--
-- Data for Name: dim_project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_project (sk_project, project_id, project_name, start_date, end_date, project_duration, project_type, project_budget, budget_consumed, priority_level) FROM stdin;
1	PRJ0001	Cloud Migration	2024-10-31	2025-11-21	386	Client	129776556	69934576	High
2	PRJ0002	IoT Monitoring Platform	2024-10-22	2025-11-25	399	External	294461278	182752899	Low
3	PRJ0003	Network Infrastructure Upgrade	2024-01-05	2024-04-26	112	External	449810534	263927189	High
4	PRJ0004	CRM Integration	2024-02-17	2024-06-04	108	Client	319665507	188238298	Low
5	PRJ0005	Supply Chain Optimization	2023-03-10	2024-01-27	323	External	437859076	87392849	Medium
6	PRJ0006	Mobile Banking Application	2024-08-28	2025-10-11	409	External	398878398	53118958	Medium
7	PRJ0007	AI Chatbot System	2025-02-07	2025-05-26	108	Client	176041315	87142713	Low
8	PRJ0008	Security Audit System	2024-12-12	2025-05-29	168	Internal	288198108	99316412	High
9	PRJ0009	ERP Implementation	2024-06-17	2025-02-12	240	Internal	251241277	125611604	Low
10	PRJ0010	Business Intelligence	2025-04-12	2025-05-29	47	External	141259276	33497411	Low
11	PRJ0011	Network Infrastructure Upgrade	2024-02-18	2025-03-12	388	Client	174655220	133788987	High
12	PRJ0012	Cloud Migration	2024-11-20	2025-02-22	94	External	204421073	191894786	High
13	PRJ0013	Mobile Banking Application	2024-10-31	2025-07-01	243	External	420609245	144270462	Medium
14	PRJ0014	Data Analytics Dashboard	2024-12-13	2025-07-12	211	External	357048659	202714730	High
15	PRJ0015	Security Audit System	2023-05-17	2024-03-04	292	External	54347562	47978853	High
16	PRJ0016	Network Infrastructure Upgrade	2025-01-05	2025-05-29	144	Client	375915537	199150873	Low
17	PRJ0017	Digital Transformation	2025-03-16	2025-05-29	74	Internal	387288135	62164487	High
18	PRJ0018	ERP Implementation	2024-12-04	2025-11-25	356	External	443182656	80551177	Low
19	PRJ0019	AI Chatbot System	2024-12-22	2025-05-29	158	Client	472255851	299592333	Medium
20	PRJ0020	Business Intelligence	2024-07-15	2025-02-21	221	Client	482980213	168452858	High
21	PRJ0021	Supply Chain Optimization	2023-02-08	2023-06-16	128	External	454881996	131125964	High
22	PRJ0022	Supply Chain Optimization	2024-06-26	2025-11-02	494	Client	57472523	27747514	High
23	PRJ0023	Mobile Banking Application	2024-11-22	2025-11-25	368	External	363833311	214561504	High
24	PRJ0024	Mobile Banking Application	2024-02-05	2024-05-17	102	Client	377535387	128845609	High
25	PRJ0025	Mobile Banking Application	2025-02-27	2025-10-29	244	Client	112639917	28760553	Low
26	PRJ0026	ERP Implementation	2024-12-14	2025-05-02	139	External	338593136	82834081	Medium
27	PRJ0027	AI Chatbot System	2025-03-26	2025-05-29	64	Client	272739435	185804259	Low
28	PRJ0028	Supply Chain Optimization	2025-03-26	2025-05-29	64	External	420591609	208926759	Low
29	PRJ0029	IoT Monitoring Platform	2024-06-28	2025-09-12	441	Internal	342307880	202561555	Low
30	PRJ0030	Cloud Migration	2023-02-01	2023-06-17	136	Internal	394512462	353325145	High
31	PRJ0031	ERP Implementation	2023-08-12	2024-12-16	492	External	86834794	84384510	Low
32	PRJ0032	Supply Chain Optimization	2024-07-10	2025-05-29	323	Internal	198860798	48839383	Low
33	PRJ0033	Cloud Migration	2023-05-18	2024-11-01	533	Internal	120761320	11994519	Medium
34	PRJ0034	Network Infrastructure Upgrade	2022-09-11	2023-04-24	225	External	118052973	109551712	Medium
35	PRJ0035	Security Audit System	2025-01-26	2025-11-25	303	Internal	325542528	68547925	Medium
\.


--
-- Data for Name: dim_task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_task (sk_task, task_id, task_name, task_category, required_skill, estimated_hours, complexity_level) FROM stdin;
1	TSK0001	Analysis Task - Web Development	Analysis	Web Development	59.30	Complex
2	TSK0002	Development Task - Web Development	Development	Web Development	102.90	Very Complex
3	TSK0003	Documentation Task - Mobile Development	Documentation	Mobile Development	87.80	Very Complex
4	TSK0004	Documentation Task - Mobile Development	Documentation	Mobile Development	44.10	Simple
5	TSK0005	Analysis Task - Mobile Development	Analysis	Mobile Development	38.80	Medium
6	TSK0006	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	119.40	Very Complex
7	TSK0007	Deployment Task - Project Management	Deployment	Project Management	64.60	Very Complex
8	TSK0008	Documentation Task - Mobile Development	Documentation	Mobile Development	103.50	Simple
9	TSK0009	Maintenance Task - Cloud Computing	Maintenance	Cloud Computing	58.60	Very Complex
10	TSK0010	Analysis Task - UI/UX Design	Analysis	UI/UX Design	100.70	Complex
11	TSK0011	Documentation Task - UI/UX Design	Documentation	UI/UX Design	43.00	Simple
12	TSK0012	Testing Task - Project Management	Testing	Project Management	114.80	Complex
13	TSK0013	Maintenance Task - Database Management	Maintenance	Database Management	18.20	Simple
14	TSK0014	Development Task - Mobile Development	Development	Mobile Development	18.80	Very Complex
15	TSK0015	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	70.30	Medium
16	TSK0016	Deployment Task - Quality Assurance	Deployment	Quality Assurance	54.00	Simple
17	TSK0017	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	116.50	Simple
18	TSK0018	Deployment Task - Project Management	Deployment	Project Management	19.60	Complex
19	TSK0019	Deployment Task - Cloud Computing	Deployment	Cloud Computing	81.60	Medium
20	TSK0020	Analysis Task - Mobile Development	Analysis	Mobile Development	102.70	Complex
21	TSK0021	Testing Task - Mobile Development	Testing	Mobile Development	72.30	Complex
22	TSK0022	Documentation Task - Web Development	Documentation	Web Development	11.20	Complex
23	TSK0023	Testing Task - Project Management	Testing	Project Management	47.30	Complex
24	TSK0024	Analysis Task - Data Analysis	Analysis	Data Analysis	15.80	Very Complex
25	TSK0025	Maintenance Task - Web Development	Maintenance	Web Development	91.60	Simple
26	TSK0026	Analysis Task - UI/UX Design	Analysis	UI/UX Design	58.80	Very Complex
27	TSK0027	Analysis Task - Quality Assurance	Analysis	Quality Assurance	88.80	Complex
28	TSK0028	Deployment Task - Mobile Development	Deployment	Mobile Development	25.40	Simple
29	TSK0029	Deployment Task - Web Development	Deployment	Web Development	38.50	Simple
30	TSK0030	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	76.00	Very Complex
31	TSK0031	Documentation Task - Project Management	Documentation	Project Management	92.60	Medium
32	TSK0032	Development Task - Quality Assurance	Development	Quality Assurance	20.40	Very Complex
33	TSK0033	Maintenance Task - Database Management	Maintenance	Database Management	13.10	Complex
34	TSK0034	Documentation Task - Web Development	Documentation	Web Development	30.90	Simple
35	TSK0035	Analysis Task - Data Analysis	Analysis	Data Analysis	40.40	Complex
36	TSK0036	Development Task - Web Development	Development	Web Development	91.70	Very Complex
37	TSK0037	Analysis Task - Data Analysis	Analysis	Data Analysis	67.60	Very Complex
38	TSK0038	Analysis Task - Quality Assurance	Analysis	Quality Assurance	52.50	Simple
39	TSK0039	Maintenance Task - Web Development	Maintenance	Web Development	10.10	Very Complex
40	TSK0040	Development Task - Quality Assurance	Development	Quality Assurance	72.20	Very Complex
41	TSK0041	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	20.90	Complex
42	TSK0042	Development Task - Quality Assurance	Development	Quality Assurance	97.70	Medium
43	TSK0043	Deployment Task - Database Management	Deployment	Database Management	17.90	Complex
44	TSK0044	Development Task - Cloud Computing	Development	Cloud Computing	74.00	Very Complex
45	TSK0045	Deployment Task - Mobile Development	Deployment	Mobile Development	105.50	Very Complex
46	TSK0046	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	45.30	Medium
47	TSK0047	Analysis Task - Mobile Development	Analysis	Mobile Development	67.40	Simple
48	TSK0048	Analysis Task - Quality Assurance	Analysis	Quality Assurance	89.50	Complex
49	TSK0049	Maintenance Task - Data Analysis	Maintenance	Data Analysis	19.50	Medium
50	TSK0050	Testing Task - Cloud Computing	Testing	Cloud Computing	75.50	Medium
51	TSK0051	Maintenance Task - Mobile Development	Maintenance	Mobile Development	114.50	Medium
52	TSK0052	Maintenance Task - Database Management	Maintenance	Database Management	92.50	Very Complex
53	TSK0053	Deployment Task - Database Management	Deployment	Database Management	104.80	Complex
54	TSK0054	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	57.30	Medium
55	TSK0055	Documentation Task - Database Management	Documentation	Database Management	97.20	Complex
56	TSK0056	Deployment Task - Web Development	Deployment	Web Development	64.80	Complex
57	TSK0057	Testing Task - Database Management	Testing	Database Management	12.20	Very Complex
58	TSK0058	Testing Task - Project Management	Testing	Project Management	80.20	Simple
59	TSK0059	Development Task - UI/UX Design	Development	UI/UX Design	73.00	Very Complex
60	TSK0060	Maintenance Task - Web Development	Maintenance	Web Development	109.80	Very Complex
61	TSK0061	Deployment Task - Cloud Computing	Deployment	Cloud Computing	75.80	Complex
62	TSK0062	Deployment Task - Data Analysis	Deployment	Data Analysis	58.50	Simple
63	TSK0063	Testing Task - Mobile Development	Testing	Mobile Development	12.40	Medium
129	TSK0129	Deployment Task - Database Management	Deployment	Database Management	22.10	Simple
64	TSK0064	Maintenance Task - Database Management	Maintenance	Database Management	66.70	Very Complex
65	TSK0065	Deployment Task - Data Analysis	Deployment	Data Analysis	49.80	Complex
66	TSK0066	Testing Task - UI/UX Design	Testing	UI/UX Design	94.70	Very Complex
67	TSK0067	Maintenance Task - Web Development	Maintenance	Web Development	15.40	Complex
68	TSK0068	Development Task - UI/UX Design	Development	UI/UX Design	36.20	Complex
69	TSK0069	Maintenance Task - Data Analysis	Maintenance	Data Analysis	17.10	Complex
70	TSK0070	Maintenance Task - Data Analysis	Maintenance	Data Analysis	42.70	Complex
71	TSK0071	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	74.60	Medium
72	TSK0072	Development Task - Project Management	Development	Project Management	80.10	Very Complex
73	TSK0073	Testing Task - Data Analysis	Testing	Data Analysis	80.40	Simple
74	TSK0074	Documentation Task - Quality Assurance	Documentation	Quality Assurance	48.60	Simple
75	TSK0075	Analysis Task - Cloud Computing	Analysis	Cloud Computing	114.10	Complex
76	TSK0076	Documentation Task - Cloud Computing	Documentation	Cloud Computing	120.00	Medium
77	TSK0077	Analysis Task - Mobile Development	Analysis	Mobile Development	102.60	Complex
78	TSK0078	Development Task - Web Development	Development	Web Development	106.20	Complex
79	TSK0079	Deployment Task - Data Analysis	Deployment	Data Analysis	25.30	Very Complex
80	TSK0080	Analysis Task - Data Analysis	Analysis	Data Analysis	12.90	Very Complex
81	TSK0081	Testing Task - Cloud Computing	Testing	Cloud Computing	76.40	Very Complex
82	TSK0082	Maintenance Task - Database Management	Maintenance	Database Management	67.80	Medium
83	TSK0083	Testing Task - Database Management	Testing	Database Management	49.20	Medium
84	TSK0084	Deployment Task - Database Management	Deployment	Database Management	94.20	Very Complex
85	TSK0085	Documentation Task - UI/UX Design	Documentation	UI/UX Design	99.50	Medium
86	TSK0086	Deployment Task - Data Analysis	Deployment	Data Analysis	13.80	Complex
87	TSK0087	Documentation Task - Quality Assurance	Documentation	Quality Assurance	87.70	Simple
88	TSK0088	Deployment Task - Mobile Development	Deployment	Mobile Development	17.40	Complex
89	TSK0089	Analysis Task - Project Management	Analysis	Project Management	109.40	Very Complex
90	TSK0090	Analysis Task - UI/UX Design	Analysis	UI/UX Design	114.00	Simple
91	TSK0091	Analysis Task - Database Management	Analysis	Database Management	112.20	Complex
92	TSK0092	Documentation Task - Web Development	Documentation	Web Development	64.20	Very Complex
93	TSK0093	Analysis Task - UI/UX Design	Analysis	UI/UX Design	50.00	Simple
94	TSK0094	Development Task - Quality Assurance	Development	Quality Assurance	102.00	Simple
95	TSK0095	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	23.40	Medium
96	TSK0096	Testing Task - Database Management	Testing	Database Management	93.00	Medium
97	TSK0097	Documentation Task - Database Management	Documentation	Database Management	109.50	Simple
98	TSK0098	Development Task - Project Management	Development	Project Management	101.50	Medium
99	TSK0099	Deployment Task - UI/UX Design	Deployment	UI/UX Design	94.90	Simple
100	TSK0100	Analysis Task - Project Management	Analysis	Project Management	13.30	Simple
101	TSK0101	Documentation Task - Database Management	Documentation	Database Management	20.40	Simple
102	TSK0102	Documentation Task - Web Development	Documentation	Web Development	88.50	Medium
103	TSK0103	Testing Task - UI/UX Design	Testing	UI/UX Design	76.90	Simple
104	TSK0104	Analysis Task - UI/UX Design	Analysis	UI/UX Design	82.40	Medium
105	TSK0105	Development Task - Quality Assurance	Development	Quality Assurance	114.80	Simple
106	TSK0106	Deployment Task - Web Development	Deployment	Web Development	105.80	Very Complex
107	TSK0107	Development Task - UI/UX Design	Development	UI/UX Design	36.40	Complex
108	TSK0108	Development Task - Quality Assurance	Development	Quality Assurance	46.60	Simple
109	TSK0109	Maintenance Task - Mobile Development	Maintenance	Mobile Development	22.90	Complex
110	TSK0110	Testing Task - Quality Assurance	Testing	Quality Assurance	101.00	Medium
111	TSK0111	Maintenance Task - Database Management	Maintenance	Database Management	78.80	Very Complex
112	TSK0112	Analysis Task - Mobile Development	Analysis	Mobile Development	12.10	Very Complex
113	TSK0113	Analysis Task - Web Development	Analysis	Web Development	107.20	Medium
114	TSK0114	Testing Task - Project Management	Testing	Project Management	118.80	Very Complex
115	TSK0115	Deployment Task - Database Management	Deployment	Database Management	12.10	Complex
116	TSK0116	Maintenance Task - Cloud Computing	Maintenance	Cloud Computing	48.00	Complex
117	TSK0117	Development Task - Quality Assurance	Development	Quality Assurance	21.90	Complex
118	TSK0118	Testing Task - UI/UX Design	Testing	UI/UX Design	91.30	Very Complex
119	TSK0119	Documentation Task - Quality Assurance	Documentation	Quality Assurance	63.60	Medium
120	TSK0120	Documentation Task - Quality Assurance	Documentation	Quality Assurance	97.70	Complex
121	TSK0121	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	56.20	Simple
122	TSK0122	Analysis Task - Project Management	Analysis	Project Management	19.50	Complex
123	TSK0123	Testing Task - Project Management	Testing	Project Management	57.90	Complex
124	TSK0124	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	85.30	Medium
125	TSK0125	Testing Task - Database Management	Testing	Database Management	89.40	Simple
126	TSK0126	Testing Task - UI/UX Design	Testing	UI/UX Design	79.60	Complex
127	TSK0127	Development Task - Mobile Development	Development	Mobile Development	48.70	Very Complex
128	TSK0128	Maintenance Task - Data Analysis	Maintenance	Data Analysis	24.00	Simple
130	TSK0130	Analysis Task - Quality Assurance	Analysis	Quality Assurance	50.90	Complex
131	TSK0131	Deployment Task - Web Development	Deployment	Web Development	84.10	Medium
132	TSK0132	Testing Task - Quality Assurance	Testing	Quality Assurance	93.50	Very Complex
133	TSK0133	Deployment Task - Data Analysis	Deployment	Data Analysis	52.60	Complex
134	TSK0134	Maintenance Task - Project Management	Maintenance	Project Management	115.60	Medium
135	TSK0135	Development Task - Data Analysis	Development	Data Analysis	66.00	Very Complex
136	TSK0136	Deployment Task - Mobile Development	Deployment	Mobile Development	94.80	Complex
137	TSK0137	Maintenance Task - Database Management	Maintenance	Database Management	119.60	Medium
138	TSK0138	Testing Task - Database Management	Testing	Database Management	21.70	Medium
139	TSK0139	Development Task - Database Management	Development	Database Management	108.70	Medium
140	TSK0140	Documentation Task - Mobile Development	Documentation	Mobile Development	82.80	Complex
141	TSK0141	Maintenance Task - Mobile Development	Maintenance	Mobile Development	107.80	Complex
142	TSK0142	Analysis Task - Data Analysis	Analysis	Data Analysis	65.00	Complex
143	TSK0143	Development Task - Cloud Computing	Development	Cloud Computing	34.50	Medium
144	TSK0144	Documentation Task - Web Development	Documentation	Web Development	70.10	Complex
145	TSK0145	Testing Task - Database Management	Testing	Database Management	76.50	Medium
146	TSK0146	Development Task - Mobile Development	Development	Mobile Development	52.60	Complex
147	TSK0147	Maintenance Task - Database Management	Maintenance	Database Management	94.10	Very Complex
148	TSK0148	Deployment Task - Mobile Development	Deployment	Mobile Development	116.90	Medium
149	TSK0149	Maintenance Task - Mobile Development	Maintenance	Mobile Development	60.20	Very Complex
150	TSK0150	Deployment Task - Quality Assurance	Deployment	Quality Assurance	106.30	Medium
151	TSK0151	Deployment Task - Data Analysis	Deployment	Data Analysis	56.50	Medium
152	TSK0152	Development Task - Mobile Development	Development	Mobile Development	42.10	Medium
153	TSK0153	Analysis Task - Quality Assurance	Analysis	Quality Assurance	46.80	Medium
154	TSK0154	Deployment Task - Project Management	Deployment	Project Management	36.10	Simple
155	TSK0155	Maintenance Task - Project Management	Maintenance	Project Management	78.00	Medium
156	TSK0156	Deployment Task - Mobile Development	Deployment	Mobile Development	74.30	Medium
157	TSK0157	Deployment Task - Data Analysis	Deployment	Data Analysis	81.80	Medium
158	TSK0158	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	100.40	Simple
159	TSK0159	Development Task - Mobile Development	Development	Mobile Development	114.20	Simple
160	TSK0160	Deployment Task - Project Management	Deployment	Project Management	93.90	Medium
161	TSK0161	Documentation Task - Web Development	Documentation	Web Development	107.60	Very Complex
162	TSK0162	Deployment Task - Project Management	Deployment	Project Management	62.10	Complex
163	TSK0163	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	58.80	Complex
164	TSK0164	Maintenance Task - Web Development	Maintenance	Web Development	57.20	Medium
165	TSK0165	Documentation Task - Database Management	Documentation	Database Management	46.10	Medium
166	TSK0166	Analysis Task - Quality Assurance	Analysis	Quality Assurance	90.20	Complex
167	TSK0167	Testing Task - UI/UX Design	Testing	UI/UX Design	93.20	Medium
168	TSK0168	Deployment Task - Mobile Development	Deployment	Mobile Development	35.10	Complex
169	TSK0169	Development Task - Project Management	Development	Project Management	35.80	Very Complex
170	TSK0170	Development Task - Web Development	Development	Web Development	113.90	Complex
171	TSK0171	Deployment Task - UI/UX Design	Deployment	UI/UX Design	115.80	Medium
172	TSK0172	Analysis Task - Quality Assurance	Analysis	Quality Assurance	29.30	Complex
173	TSK0173	Analysis Task - Database Management	Analysis	Database Management	63.90	Very Complex
174	TSK0174	Testing Task - Database Management	Testing	Database Management	18.10	Simple
175	TSK0175	Documentation Task - Database Management	Documentation	Database Management	32.10	Medium
176	TSK0176	Testing Task - Web Development	Testing	Web Development	39.50	Simple
177	TSK0177	Deployment Task - Database Management	Deployment	Database Management	68.10	Complex
178	TSK0178	Development Task - UI/UX Design	Development	UI/UX Design	106.80	Medium
179	TSK0179	Maintenance Task - Quality Assurance	Maintenance	Quality Assurance	49.00	Very Complex
180	TSK0180	Documentation Task - Web Development	Documentation	Web Development	48.60	Medium
181	TSK0181	Testing Task - Mobile Development	Testing	Mobile Development	64.50	Very Complex
182	TSK0182	Deployment Task - Project Management	Deployment	Project Management	22.40	Simple
183	TSK0183	Development Task - UI/UX Design	Development	UI/UX Design	97.00	Complex
184	TSK0184	Testing Task - Quality Assurance	Testing	Quality Assurance	30.30	Medium
185	TSK0185	Deployment Task - UI/UX Design	Deployment	UI/UX Design	13.10	Simple
186	TSK0186	Analysis Task - Quality Assurance	Analysis	Quality Assurance	66.20	Very Complex
187	TSK0187	Analysis Task - Data Analysis	Analysis	Data Analysis	112.30	Complex
188	TSK0188	Testing Task - Data Analysis	Testing	Data Analysis	118.90	Very Complex
189	TSK0189	Maintenance Task - Project Management	Maintenance	Project Management	64.80	Complex
190	TSK0190	Deployment Task - Database Management	Deployment	Database Management	61.20	Complex
191	TSK0191	Development Task - Quality Assurance	Development	Quality Assurance	83.50	Complex
192	TSK0192	Documentation Task - Project Management	Documentation	Project Management	74.90	Simple
193	TSK0193	Testing Task - Cloud Computing	Testing	Cloud Computing	73.40	Simple
194	TSK0194	Analysis Task - UI/UX Design	Analysis	UI/UX Design	100.00	Medium
195	TSK0195	Analysis Task - Web Development	Analysis	Web Development	29.40	Simple
196	TSK0196	Documentation Task - Quality Assurance	Documentation	Quality Assurance	25.00	Very Complex
197	TSK0197	Maintenance Task - Cloud Computing	Maintenance	Cloud Computing	64.20	Very Complex
198	TSK0198	Deployment Task - Database Management	Deployment	Database Management	87.00	Simple
199	TSK0199	Deployment Task - Cloud Computing	Deployment	Cloud Computing	119.80	Complex
200	TSK0200	Documentation Task - UI/UX Design	Documentation	UI/UX Design	115.10	Complex
201	TSK0201	Documentation Task - Quality Assurance	Documentation	Quality Assurance	83.70	Complex
202	TSK0202	Maintenance Task - Project Management	Maintenance	Project Management	29.50	Very Complex
203	TSK0203	Analysis Task - Project Management	Analysis	Project Management	33.20	Complex
204	TSK0204	Testing Task - Project Management	Testing	Project Management	85.30	Medium
205	TSK0205	Documentation Task - Quality Assurance	Documentation	Quality Assurance	47.10	Very Complex
206	TSK0206	Maintenance Task - Project Management	Maintenance	Project Management	21.60	Complex
207	TSK0207	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	99.70	Very Complex
208	TSK0208	Analysis Task - Project Management	Analysis	Project Management	40.20	Simple
209	TSK0209	Maintenance Task - Mobile Development	Maintenance	Mobile Development	111.50	Complex
210	TSK0210	Maintenance Task - Project Management	Maintenance	Project Management	32.00	Very Complex
211	TSK0211	Deployment Task - Project Management	Deployment	Project Management	23.40	Complex
212	TSK0212	Deployment Task - Cloud Computing	Deployment	Cloud Computing	13.70	Medium
213	TSK0213	Deployment Task - Cloud Computing	Deployment	Cloud Computing	13.90	Medium
214	TSK0214	Documentation Task - Quality Assurance	Documentation	Quality Assurance	19.30	Very Complex
215	TSK0215	Analysis Task - Web Development	Analysis	Web Development	53.60	Medium
216	TSK0216	Documentation Task - Database Management	Documentation	Database Management	92.70	Medium
217	TSK0217	Testing Task - Quality Assurance	Testing	Quality Assurance	80.30	Complex
218	TSK0218	Development Task - Cloud Computing	Development	Cloud Computing	110.30	Simple
219	TSK0219	Analysis Task - UI/UX Design	Analysis	UI/UX Design	112.60	Medium
220	TSK0220	Development Task - UI/UX Design	Development	UI/UX Design	28.90	Very Complex
221	TSK0221	Maintenance Task - Project Management	Maintenance	Project Management	9.00	Simple
222	TSK0222	Deployment Task - Mobile Development	Deployment	Mobile Development	39.90	Complex
223	TSK0223	Maintenance Task - Database Management	Maintenance	Database Management	103.30	Medium
224	TSK0224	Documentation Task - Project Management	Documentation	Project Management	98.60	Medium
225	TSK0225	Testing Task - Data Analysis	Testing	Data Analysis	80.60	Very Complex
226	TSK0226	Maintenance Task - Data Analysis	Maintenance	Data Analysis	90.50	Simple
227	TSK0227	Testing Task - Cloud Computing	Testing	Cloud Computing	76.40	Medium
228	TSK0228	Maintenance Task - UI/UX Design	Maintenance	UI/UX Design	65.70	Very Complex
229	TSK0229	Development Task - UI/UX Design	Development	UI/UX Design	28.70	Simple
230	TSK0230	Analysis Task - Database Management	Analysis	Database Management	112.80	Complex
231	TSK0231	Development Task - Project Management	Development	Project Management	34.40	Very Complex
232	TSK0232	Testing Task - Quality Assurance	Testing	Quality Assurance	73.20	Complex
233	TSK0233	Deployment Task - Web Development	Deployment	Web Development	81.20	Complex
234	TSK0234	Maintenance Task - Cloud Computing	Maintenance	Cloud Computing	82.80	Simple
235	TSK0235	Documentation Task - Project Management	Documentation	Project Management	53.40	Medium
236	TSK0236	Deployment Task - Project Management	Deployment	Project Management	79.50	Simple
237	TSK0237	Testing Task - Quality Assurance	Testing	Quality Assurance	32.50	Medium
238	TSK0238	Analysis Task - Database Management	Analysis	Database Management	59.00	Medium
239	TSK0239	Deployment Task - Quality Assurance	Deployment	Quality Assurance	86.60	Very Complex
240	TSK0240	Documentation Task - Cloud Computing	Documentation	Cloud Computing	84.20	Medium
241	TSK0241	Deployment Task - Mobile Development	Deployment	Mobile Development	67.20	Very Complex
242	TSK0242	Testing Task - Mobile Development	Testing	Mobile Development	14.90	Simple
243	TSK0243	Deployment Task - Cloud Computing	Deployment	Cloud Computing	26.40	Medium
244	TSK0244	Deployment Task - Database Management	Deployment	Database Management	84.20	Simple
245	TSK0245	Maintenance Task - Database Management	Maintenance	Database Management	108.70	Simple
246	TSK0246	Documentation Task - Web Development	Documentation	Web Development	22.80	Very Complex
247	TSK0247	Documentation Task - Database Management	Documentation	Database Management	70.60	Simple
248	TSK0248	Maintenance Task - Project Management	Maintenance	Project Management	52.30	Simple
249	TSK0249	Development Task - Cloud Computing	Development	Cloud Computing	13.10	Simple
250	TSK0250	Testing Task - Mobile Development	Testing	Mobile Development	112.70	Simple
\.


--
-- Data for Name: dim_time; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_time (sk_time, work_date, hari, bulan, kuartal, tahun) FROM stdin;
20220101	2022-01-01	1	1	Q1	2022
20220102	2022-01-02	2	1	Q1	2022
20220103	2022-01-03	3	1	Q1	2022
20220104	2022-01-04	4	1	Q1	2022
20220105	2022-01-05	5	1	Q1	2022
20220106	2022-01-06	6	1	Q1	2022
20220107	2022-01-07	7	1	Q1	2022
20220108	2022-01-08	8	1	Q1	2022
20220109	2022-01-09	9	1	Q1	2022
20220110	2022-01-10	10	1	Q1	2022
20220111	2022-01-11	11	1	Q1	2022
20220112	2022-01-12	12	1	Q1	2022
20220113	2022-01-13	13	1	Q1	2022
20220114	2022-01-14	14	1	Q1	2022
20220115	2022-01-15	15	1	Q1	2022
20220116	2022-01-16	16	1	Q1	2022
20220117	2022-01-17	17	1	Q1	2022
20220118	2022-01-18	18	1	Q1	2022
20220119	2022-01-19	19	1	Q1	2022
20220120	2022-01-20	20	1	Q1	2022
20220121	2022-01-21	21	1	Q1	2022
20220122	2022-01-22	22	1	Q1	2022
20220123	2022-01-23	23	1	Q1	2022
20220124	2022-01-24	24	1	Q1	2022
20220125	2022-01-25	25	1	Q1	2022
20220126	2022-01-26	26	1	Q1	2022
20220127	2022-01-27	27	1	Q1	2022
20220128	2022-01-28	28	1	Q1	2022
20220129	2022-01-29	29	1	Q1	2022
20220130	2022-01-30	30	1	Q1	2022
20220131	2022-01-31	31	1	Q1	2022
20220201	2022-02-01	1	2	Q1	2022
20220202	2022-02-02	2	2	Q1	2022
20220203	2022-02-03	3	2	Q1	2022
20220204	2022-02-04	4	2	Q1	2022
20220205	2022-02-05	5	2	Q1	2022
20220206	2022-02-06	6	2	Q1	2022
20220207	2022-02-07	7	2	Q1	2022
20220208	2022-02-08	8	2	Q1	2022
20220209	2022-02-09	9	2	Q1	2022
20220210	2022-02-10	10	2	Q1	2022
20220211	2022-02-11	11	2	Q1	2022
20220212	2022-02-12	12	2	Q1	2022
20220213	2022-02-13	13	2	Q1	2022
20220214	2022-02-14	14	2	Q1	2022
20220215	2022-02-15	15	2	Q1	2022
20220216	2022-02-16	16	2	Q1	2022
20220217	2022-02-17	17	2	Q1	2022
20220218	2022-02-18	18	2	Q1	2022
20220219	2022-02-19	19	2	Q1	2022
20220220	2022-02-20	20	2	Q1	2022
20220221	2022-02-21	21	2	Q1	2022
20220222	2022-02-22	22	2	Q1	2022
20220223	2022-02-23	23	2	Q1	2022
20220224	2022-02-24	24	2	Q1	2022
20220225	2022-02-25	25	2	Q1	2022
20220226	2022-02-26	26	2	Q1	2022
20220227	2022-02-27	27	2	Q1	2022
20220228	2022-02-28	28	2	Q1	2022
20220301	2022-03-01	1	3	Q1	2022
20220302	2022-03-02	2	3	Q1	2022
20220303	2022-03-03	3	3	Q1	2022
20220304	2022-03-04	4	3	Q1	2022
20220305	2022-03-05	5	3	Q1	2022
20220306	2022-03-06	6	3	Q1	2022
20220307	2022-03-07	7	3	Q1	2022
20220308	2022-03-08	8	3	Q1	2022
20220309	2022-03-09	9	3	Q1	2022
20220310	2022-03-10	10	3	Q1	2022
20220311	2022-03-11	11	3	Q1	2022
20220312	2022-03-12	12	3	Q1	2022
20220313	2022-03-13	13	3	Q1	2022
20220314	2022-03-14	14	3	Q1	2022
20220315	2022-03-15	15	3	Q1	2022
20220316	2022-03-16	16	3	Q1	2022
20220317	2022-03-17	17	3	Q1	2022
20220318	2022-03-18	18	3	Q1	2022
20220319	2022-03-19	19	3	Q1	2022
20220320	2022-03-20	20	3	Q1	2022
20220321	2022-03-21	21	3	Q1	2022
20220322	2022-03-22	22	3	Q1	2022
20220323	2022-03-23	23	3	Q1	2022
20220324	2022-03-24	24	3	Q1	2022
20220325	2022-03-25	25	3	Q1	2022
20220326	2022-03-26	26	3	Q1	2022
20220327	2022-03-27	27	3	Q1	2022
20220328	2022-03-28	28	3	Q1	2022
20220329	2022-03-29	29	3	Q1	2022
20220330	2022-03-30	30	3	Q1	2022
20220331	2022-03-31	31	3	Q1	2022
20220401	2022-04-01	1	4	Q2	2022
20220402	2022-04-02	2	4	Q2	2022
20220403	2022-04-03	3	4	Q2	2022
20220404	2022-04-04	4	4	Q2	2022
20220405	2022-04-05	5	4	Q2	2022
20220406	2022-04-06	6	4	Q2	2022
20220407	2022-04-07	7	4	Q2	2022
20220408	2022-04-08	8	4	Q2	2022
20220409	2022-04-09	9	4	Q2	2022
20220410	2022-04-10	10	4	Q2	2022
20220411	2022-04-11	11	4	Q2	2022
20220412	2022-04-12	12	4	Q2	2022
20220413	2022-04-13	13	4	Q2	2022
20220414	2022-04-14	14	4	Q2	2022
20220415	2022-04-15	15	4	Q2	2022
20220416	2022-04-16	16	4	Q2	2022
20220417	2022-04-17	17	4	Q2	2022
20220418	2022-04-18	18	4	Q2	2022
20220419	2022-04-19	19	4	Q2	2022
20220420	2022-04-20	20	4	Q2	2022
20220421	2022-04-21	21	4	Q2	2022
20220422	2022-04-22	22	4	Q2	2022
20220423	2022-04-23	23	4	Q2	2022
20220424	2022-04-24	24	4	Q2	2022
20220425	2022-04-25	25	4	Q2	2022
20220426	2022-04-26	26	4	Q2	2022
20220427	2022-04-27	27	4	Q2	2022
20220428	2022-04-28	28	4	Q2	2022
20220429	2022-04-29	29	4	Q2	2022
20220430	2022-04-30	30	4	Q2	2022
20220501	2022-05-01	1	5	Q2	2022
20220502	2022-05-02	2	5	Q2	2022
20220503	2022-05-03	3	5	Q2	2022
20220504	2022-05-04	4	5	Q2	2022
20220505	2022-05-05	5	5	Q2	2022
20220506	2022-05-06	6	5	Q2	2022
20220507	2022-05-07	7	5	Q2	2022
20220508	2022-05-08	8	5	Q2	2022
20220509	2022-05-09	9	5	Q2	2022
20220510	2022-05-10	10	5	Q2	2022
20220511	2022-05-11	11	5	Q2	2022
20220512	2022-05-12	12	5	Q2	2022
20220513	2022-05-13	13	5	Q2	2022
20220514	2022-05-14	14	5	Q2	2022
20220515	2022-05-15	15	5	Q2	2022
20220516	2022-05-16	16	5	Q2	2022
20220517	2022-05-17	17	5	Q2	2022
20220518	2022-05-18	18	5	Q2	2022
20220519	2022-05-19	19	5	Q2	2022
20220520	2022-05-20	20	5	Q2	2022
20220521	2022-05-21	21	5	Q2	2022
20220522	2022-05-22	22	5	Q2	2022
20220523	2022-05-23	23	5	Q2	2022
20220524	2022-05-24	24	5	Q2	2022
20220525	2022-05-25	25	5	Q2	2022
20220526	2022-05-26	26	5	Q2	2022
20220527	2022-05-27	27	5	Q2	2022
20220528	2022-05-28	28	5	Q2	2022
20220529	2022-05-29	29	5	Q2	2022
20220530	2022-05-30	30	5	Q2	2022
20220531	2022-05-31	31	5	Q2	2022
20220601	2022-06-01	1	6	Q2	2022
20220602	2022-06-02	2	6	Q2	2022
20220603	2022-06-03	3	6	Q2	2022
20220604	2022-06-04	4	6	Q2	2022
20220605	2022-06-05	5	6	Q2	2022
20220606	2022-06-06	6	6	Q2	2022
20220607	2022-06-07	7	6	Q2	2022
20220608	2022-06-08	8	6	Q2	2022
20220609	2022-06-09	9	6	Q2	2022
20220610	2022-06-10	10	6	Q2	2022
20220611	2022-06-11	11	6	Q2	2022
20220612	2022-06-12	12	6	Q2	2022
20220613	2022-06-13	13	6	Q2	2022
20220614	2022-06-14	14	6	Q2	2022
20220615	2022-06-15	15	6	Q2	2022
20220616	2022-06-16	16	6	Q2	2022
20220617	2022-06-17	17	6	Q2	2022
20220618	2022-06-18	18	6	Q2	2022
20220619	2022-06-19	19	6	Q2	2022
20220620	2022-06-20	20	6	Q2	2022
20220621	2022-06-21	21	6	Q2	2022
20220622	2022-06-22	22	6	Q2	2022
20220623	2022-06-23	23	6	Q2	2022
20220624	2022-06-24	24	6	Q2	2022
20220625	2022-06-25	25	6	Q2	2022
20220626	2022-06-26	26	6	Q2	2022
20220627	2022-06-27	27	6	Q2	2022
20220628	2022-06-28	28	6	Q2	2022
20220629	2022-06-29	29	6	Q2	2022
20220630	2022-06-30	30	6	Q2	2022
20220701	2022-07-01	1	7	Q3	2022
20220702	2022-07-02	2	7	Q3	2022
20220703	2022-07-03	3	7	Q3	2022
20220704	2022-07-04	4	7	Q3	2022
20220705	2022-07-05	5	7	Q3	2022
20220706	2022-07-06	6	7	Q3	2022
20220707	2022-07-07	7	7	Q3	2022
20220708	2022-07-08	8	7	Q3	2022
20220709	2022-07-09	9	7	Q3	2022
20220710	2022-07-10	10	7	Q3	2022
20220711	2022-07-11	11	7	Q3	2022
20220712	2022-07-12	12	7	Q3	2022
20220713	2022-07-13	13	7	Q3	2022
20220714	2022-07-14	14	7	Q3	2022
20220715	2022-07-15	15	7	Q3	2022
20220716	2022-07-16	16	7	Q3	2022
20220717	2022-07-17	17	7	Q3	2022
20220718	2022-07-18	18	7	Q3	2022
20220719	2022-07-19	19	7	Q3	2022
20220720	2022-07-20	20	7	Q3	2022
20220721	2022-07-21	21	7	Q3	2022
20220722	2022-07-22	22	7	Q3	2022
20220723	2022-07-23	23	7	Q3	2022
20220724	2022-07-24	24	7	Q3	2022
20220725	2022-07-25	25	7	Q3	2022
20220726	2022-07-26	26	7	Q3	2022
20220727	2022-07-27	27	7	Q3	2022
20220728	2022-07-28	28	7	Q3	2022
20220729	2022-07-29	29	7	Q3	2022
20220730	2022-07-30	30	7	Q3	2022
20220731	2022-07-31	31	7	Q3	2022
20220801	2022-08-01	1	8	Q3	2022
20220802	2022-08-02	2	8	Q3	2022
20220803	2022-08-03	3	8	Q3	2022
20220804	2022-08-04	4	8	Q3	2022
20220805	2022-08-05	5	8	Q3	2022
20220806	2022-08-06	6	8	Q3	2022
20220807	2022-08-07	7	8	Q3	2022
20220808	2022-08-08	8	8	Q3	2022
20220809	2022-08-09	9	8	Q3	2022
20220810	2022-08-10	10	8	Q3	2022
20220811	2022-08-11	11	8	Q3	2022
20220812	2022-08-12	12	8	Q3	2022
20220813	2022-08-13	13	8	Q3	2022
20220814	2022-08-14	14	8	Q3	2022
20220815	2022-08-15	15	8	Q3	2022
20220816	2022-08-16	16	8	Q3	2022
20220817	2022-08-17	17	8	Q3	2022
20220818	2022-08-18	18	8	Q3	2022
20220819	2022-08-19	19	8	Q3	2022
20220820	2022-08-20	20	8	Q3	2022
20220821	2022-08-21	21	8	Q3	2022
20220822	2022-08-22	22	8	Q3	2022
20220823	2022-08-23	23	8	Q3	2022
20220824	2022-08-24	24	8	Q3	2022
20220825	2022-08-25	25	8	Q3	2022
20220826	2022-08-26	26	8	Q3	2022
20220827	2022-08-27	27	8	Q3	2022
20220828	2022-08-28	28	8	Q3	2022
20220829	2022-08-29	29	8	Q3	2022
20220830	2022-08-30	30	8	Q3	2022
20220831	2022-08-31	31	8	Q3	2022
20220901	2022-09-01	1	9	Q3	2022
20220902	2022-09-02	2	9	Q3	2022
20220903	2022-09-03	3	9	Q3	2022
20220904	2022-09-04	4	9	Q3	2022
20220905	2022-09-05	5	9	Q3	2022
20220906	2022-09-06	6	9	Q3	2022
20220907	2022-09-07	7	9	Q3	2022
20220908	2022-09-08	8	9	Q3	2022
20220909	2022-09-09	9	9	Q3	2022
20220910	2022-09-10	10	9	Q3	2022
20220911	2022-09-11	11	9	Q3	2022
20220912	2022-09-12	12	9	Q3	2022
20220913	2022-09-13	13	9	Q3	2022
20220914	2022-09-14	14	9	Q3	2022
20220915	2022-09-15	15	9	Q3	2022
20220916	2022-09-16	16	9	Q3	2022
20220917	2022-09-17	17	9	Q3	2022
20220918	2022-09-18	18	9	Q3	2022
20220919	2022-09-19	19	9	Q3	2022
20220920	2022-09-20	20	9	Q3	2022
20220921	2022-09-21	21	9	Q3	2022
20220922	2022-09-22	22	9	Q3	2022
20220923	2022-09-23	23	9	Q3	2022
20220924	2022-09-24	24	9	Q3	2022
20220925	2022-09-25	25	9	Q3	2022
20220926	2022-09-26	26	9	Q3	2022
20220927	2022-09-27	27	9	Q3	2022
20220928	2022-09-28	28	9	Q3	2022
20220929	2022-09-29	29	9	Q3	2022
20220930	2022-09-30	30	9	Q3	2022
20221001	2022-10-01	1	10	Q4	2022
20221002	2022-10-02	2	10	Q4	2022
20221003	2022-10-03	3	10	Q4	2022
20221004	2022-10-04	4	10	Q4	2022
20221005	2022-10-05	5	10	Q4	2022
20221006	2022-10-06	6	10	Q4	2022
20221007	2022-10-07	7	10	Q4	2022
20221008	2022-10-08	8	10	Q4	2022
20221009	2022-10-09	9	10	Q4	2022
20221010	2022-10-10	10	10	Q4	2022
20221011	2022-10-11	11	10	Q4	2022
20221012	2022-10-12	12	10	Q4	2022
20221013	2022-10-13	13	10	Q4	2022
20221014	2022-10-14	14	10	Q4	2022
20221015	2022-10-15	15	10	Q4	2022
20221016	2022-10-16	16	10	Q4	2022
20221017	2022-10-17	17	10	Q4	2022
20221018	2022-10-18	18	10	Q4	2022
20221019	2022-10-19	19	10	Q4	2022
20221020	2022-10-20	20	10	Q4	2022
20221021	2022-10-21	21	10	Q4	2022
20221022	2022-10-22	22	10	Q4	2022
20221023	2022-10-23	23	10	Q4	2022
20221024	2022-10-24	24	10	Q4	2022
20221025	2022-10-25	25	10	Q4	2022
20221026	2022-10-26	26	10	Q4	2022
20221027	2022-10-27	27	10	Q4	2022
20221028	2022-10-28	28	10	Q4	2022
20221029	2022-10-29	29	10	Q4	2022
20221030	2022-10-30	30	10	Q4	2022
20221031	2022-10-31	31	10	Q4	2022
20221101	2022-11-01	1	11	Q4	2022
20221102	2022-11-02	2	11	Q4	2022
20221103	2022-11-03	3	11	Q4	2022
20221104	2022-11-04	4	11	Q4	2022
20221105	2022-11-05	5	11	Q4	2022
20221106	2022-11-06	6	11	Q4	2022
20221107	2022-11-07	7	11	Q4	2022
20221108	2022-11-08	8	11	Q4	2022
20221109	2022-11-09	9	11	Q4	2022
20221110	2022-11-10	10	11	Q4	2022
20221111	2022-11-11	11	11	Q4	2022
20221112	2022-11-12	12	11	Q4	2022
20221113	2022-11-13	13	11	Q4	2022
20221114	2022-11-14	14	11	Q4	2022
20221115	2022-11-15	15	11	Q4	2022
20221116	2022-11-16	16	11	Q4	2022
20221117	2022-11-17	17	11	Q4	2022
20221118	2022-11-18	18	11	Q4	2022
20221119	2022-11-19	19	11	Q4	2022
20221120	2022-11-20	20	11	Q4	2022
20221121	2022-11-21	21	11	Q4	2022
20221122	2022-11-22	22	11	Q4	2022
20221123	2022-11-23	23	11	Q4	2022
20221124	2022-11-24	24	11	Q4	2022
20221125	2022-11-25	25	11	Q4	2022
20221126	2022-11-26	26	11	Q4	2022
20221127	2022-11-27	27	11	Q4	2022
20221128	2022-11-28	28	11	Q4	2022
20221129	2022-11-29	29	11	Q4	2022
20221130	2022-11-30	30	11	Q4	2022
20221201	2022-12-01	1	12	Q4	2022
20221202	2022-12-02	2	12	Q4	2022
20221203	2022-12-03	3	12	Q4	2022
20221204	2022-12-04	4	12	Q4	2022
20221205	2022-12-05	5	12	Q4	2022
20221206	2022-12-06	6	12	Q4	2022
20221207	2022-12-07	7	12	Q4	2022
20221208	2022-12-08	8	12	Q4	2022
20221209	2022-12-09	9	12	Q4	2022
20221210	2022-12-10	10	12	Q4	2022
20221211	2022-12-11	11	12	Q4	2022
20221212	2022-12-12	12	12	Q4	2022
20221213	2022-12-13	13	12	Q4	2022
20221214	2022-12-14	14	12	Q4	2022
20221215	2022-12-15	15	12	Q4	2022
20221216	2022-12-16	16	12	Q4	2022
20221217	2022-12-17	17	12	Q4	2022
20221218	2022-12-18	18	12	Q4	2022
20221219	2022-12-19	19	12	Q4	2022
20221220	2022-12-20	20	12	Q4	2022
20221221	2022-12-21	21	12	Q4	2022
20221222	2022-12-22	22	12	Q4	2022
20221223	2022-12-23	23	12	Q4	2022
20221224	2022-12-24	24	12	Q4	2022
20221225	2022-12-25	25	12	Q4	2022
20221226	2022-12-26	26	12	Q4	2022
20221227	2022-12-27	27	12	Q4	2022
20221228	2022-12-28	28	12	Q4	2022
20221229	2022-12-29	29	12	Q4	2022
20221230	2022-12-30	30	12	Q4	2022
20221231	2022-12-31	31	12	Q4	2022
20230101	2023-01-01	1	1	Q1	2023
20230102	2023-01-02	2	1	Q1	2023
20230103	2023-01-03	3	1	Q1	2023
20230104	2023-01-04	4	1	Q1	2023
20230105	2023-01-05	5	1	Q1	2023
20230106	2023-01-06	6	1	Q1	2023
20230107	2023-01-07	7	1	Q1	2023
20230108	2023-01-08	8	1	Q1	2023
20230109	2023-01-09	9	1	Q1	2023
20230110	2023-01-10	10	1	Q1	2023
20230111	2023-01-11	11	1	Q1	2023
20230112	2023-01-12	12	1	Q1	2023
20230113	2023-01-13	13	1	Q1	2023
20230114	2023-01-14	14	1	Q1	2023
20230115	2023-01-15	15	1	Q1	2023
20230116	2023-01-16	16	1	Q1	2023
20230117	2023-01-17	17	1	Q1	2023
20230118	2023-01-18	18	1	Q1	2023
20230119	2023-01-19	19	1	Q1	2023
20230120	2023-01-20	20	1	Q1	2023
20230121	2023-01-21	21	1	Q1	2023
20230122	2023-01-22	22	1	Q1	2023
20230123	2023-01-23	23	1	Q1	2023
20230124	2023-01-24	24	1	Q1	2023
20230125	2023-01-25	25	1	Q1	2023
20230126	2023-01-26	26	1	Q1	2023
20230127	2023-01-27	27	1	Q1	2023
20230128	2023-01-28	28	1	Q1	2023
20230129	2023-01-29	29	1	Q1	2023
20230130	2023-01-30	30	1	Q1	2023
20230131	2023-01-31	31	1	Q1	2023
20230201	2023-02-01	1	2	Q1	2023
20230202	2023-02-02	2	2	Q1	2023
20230203	2023-02-03	3	2	Q1	2023
20230204	2023-02-04	4	2	Q1	2023
20230205	2023-02-05	5	2	Q1	2023
20230206	2023-02-06	6	2	Q1	2023
20230207	2023-02-07	7	2	Q1	2023
20230208	2023-02-08	8	2	Q1	2023
20230209	2023-02-09	9	2	Q1	2023
20230210	2023-02-10	10	2	Q1	2023
20230211	2023-02-11	11	2	Q1	2023
20230212	2023-02-12	12	2	Q1	2023
20230213	2023-02-13	13	2	Q1	2023
20230214	2023-02-14	14	2	Q1	2023
20230215	2023-02-15	15	2	Q1	2023
20230216	2023-02-16	16	2	Q1	2023
20230217	2023-02-17	17	2	Q1	2023
20230218	2023-02-18	18	2	Q1	2023
20230219	2023-02-19	19	2	Q1	2023
20230220	2023-02-20	20	2	Q1	2023
20230221	2023-02-21	21	2	Q1	2023
20230222	2023-02-22	22	2	Q1	2023
20230223	2023-02-23	23	2	Q1	2023
20230224	2023-02-24	24	2	Q1	2023
20230225	2023-02-25	25	2	Q1	2023
20230226	2023-02-26	26	2	Q1	2023
20230227	2023-02-27	27	2	Q1	2023
20230228	2023-02-28	28	2	Q1	2023
20230301	2023-03-01	1	3	Q1	2023
20230302	2023-03-02	2	3	Q1	2023
20230303	2023-03-03	3	3	Q1	2023
20230304	2023-03-04	4	3	Q1	2023
20230305	2023-03-05	5	3	Q1	2023
20230306	2023-03-06	6	3	Q1	2023
20230307	2023-03-07	7	3	Q1	2023
20230308	2023-03-08	8	3	Q1	2023
20230309	2023-03-09	9	3	Q1	2023
20230310	2023-03-10	10	3	Q1	2023
20230311	2023-03-11	11	3	Q1	2023
20230312	2023-03-12	12	3	Q1	2023
20230313	2023-03-13	13	3	Q1	2023
20230314	2023-03-14	14	3	Q1	2023
20230315	2023-03-15	15	3	Q1	2023
20230316	2023-03-16	16	3	Q1	2023
20230317	2023-03-17	17	3	Q1	2023
20230318	2023-03-18	18	3	Q1	2023
20230319	2023-03-19	19	3	Q1	2023
20230320	2023-03-20	20	3	Q1	2023
20230321	2023-03-21	21	3	Q1	2023
20230322	2023-03-22	22	3	Q1	2023
20230323	2023-03-23	23	3	Q1	2023
20230324	2023-03-24	24	3	Q1	2023
20230325	2023-03-25	25	3	Q1	2023
20230326	2023-03-26	26	3	Q1	2023
20230327	2023-03-27	27	3	Q1	2023
20230328	2023-03-28	28	3	Q1	2023
20230329	2023-03-29	29	3	Q1	2023
20230330	2023-03-30	30	3	Q1	2023
20230331	2023-03-31	31	3	Q1	2023
20230401	2023-04-01	1	4	Q2	2023
20230402	2023-04-02	2	4	Q2	2023
20230403	2023-04-03	3	4	Q2	2023
20230404	2023-04-04	4	4	Q2	2023
20230405	2023-04-05	5	4	Q2	2023
20230406	2023-04-06	6	4	Q2	2023
20230407	2023-04-07	7	4	Q2	2023
20230408	2023-04-08	8	4	Q2	2023
20230409	2023-04-09	9	4	Q2	2023
20230410	2023-04-10	10	4	Q2	2023
20230411	2023-04-11	11	4	Q2	2023
20230412	2023-04-12	12	4	Q2	2023
20230413	2023-04-13	13	4	Q2	2023
20230414	2023-04-14	14	4	Q2	2023
20230415	2023-04-15	15	4	Q2	2023
20230416	2023-04-16	16	4	Q2	2023
20230417	2023-04-17	17	4	Q2	2023
20230418	2023-04-18	18	4	Q2	2023
20230419	2023-04-19	19	4	Q2	2023
20230420	2023-04-20	20	4	Q2	2023
20230421	2023-04-21	21	4	Q2	2023
20230422	2023-04-22	22	4	Q2	2023
20230423	2023-04-23	23	4	Q2	2023
20230424	2023-04-24	24	4	Q2	2023
20230425	2023-04-25	25	4	Q2	2023
20230426	2023-04-26	26	4	Q2	2023
20230427	2023-04-27	27	4	Q2	2023
20230428	2023-04-28	28	4	Q2	2023
20230429	2023-04-29	29	4	Q2	2023
20230430	2023-04-30	30	4	Q2	2023
20230501	2023-05-01	1	5	Q2	2023
20230502	2023-05-02	2	5	Q2	2023
20230503	2023-05-03	3	5	Q2	2023
20230504	2023-05-04	4	5	Q2	2023
20230505	2023-05-05	5	5	Q2	2023
20230506	2023-05-06	6	5	Q2	2023
20230507	2023-05-07	7	5	Q2	2023
20230508	2023-05-08	8	5	Q2	2023
20230509	2023-05-09	9	5	Q2	2023
20230510	2023-05-10	10	5	Q2	2023
20230511	2023-05-11	11	5	Q2	2023
20230512	2023-05-12	12	5	Q2	2023
20230513	2023-05-13	13	5	Q2	2023
20230514	2023-05-14	14	5	Q2	2023
20230515	2023-05-15	15	5	Q2	2023
20230516	2023-05-16	16	5	Q2	2023
20230517	2023-05-17	17	5	Q2	2023
20230518	2023-05-18	18	5	Q2	2023
20230519	2023-05-19	19	5	Q2	2023
20230520	2023-05-20	20	5	Q2	2023
20230521	2023-05-21	21	5	Q2	2023
20230522	2023-05-22	22	5	Q2	2023
20230523	2023-05-23	23	5	Q2	2023
20230524	2023-05-24	24	5	Q2	2023
20230525	2023-05-25	25	5	Q2	2023
20230526	2023-05-26	26	5	Q2	2023
20230527	2023-05-27	27	5	Q2	2023
20230528	2023-05-28	28	5	Q2	2023
20230529	2023-05-29	29	5	Q2	2023
20230530	2023-05-30	30	5	Q2	2023
20230531	2023-05-31	31	5	Q2	2023
20230601	2023-06-01	1	6	Q2	2023
20230602	2023-06-02	2	6	Q2	2023
20230603	2023-06-03	3	6	Q2	2023
20230604	2023-06-04	4	6	Q2	2023
20230605	2023-06-05	5	6	Q2	2023
20230606	2023-06-06	6	6	Q2	2023
20230607	2023-06-07	7	6	Q2	2023
20230608	2023-06-08	8	6	Q2	2023
20230609	2023-06-09	9	6	Q2	2023
20230610	2023-06-10	10	6	Q2	2023
20230611	2023-06-11	11	6	Q2	2023
20230612	2023-06-12	12	6	Q2	2023
20230613	2023-06-13	13	6	Q2	2023
20230614	2023-06-14	14	6	Q2	2023
20230615	2023-06-15	15	6	Q2	2023
20230616	2023-06-16	16	6	Q2	2023
20230617	2023-06-17	17	6	Q2	2023
20230618	2023-06-18	18	6	Q2	2023
20230619	2023-06-19	19	6	Q2	2023
20230620	2023-06-20	20	6	Q2	2023
20230621	2023-06-21	21	6	Q2	2023
20230622	2023-06-22	22	6	Q2	2023
20230623	2023-06-23	23	6	Q2	2023
20230624	2023-06-24	24	6	Q2	2023
20230625	2023-06-25	25	6	Q2	2023
20230626	2023-06-26	26	6	Q2	2023
20230627	2023-06-27	27	6	Q2	2023
20230628	2023-06-28	28	6	Q2	2023
20230629	2023-06-29	29	6	Q2	2023
20230630	2023-06-30	30	6	Q2	2023
20230701	2023-07-01	1	7	Q3	2023
20230702	2023-07-02	2	7	Q3	2023
20230703	2023-07-03	3	7	Q3	2023
20230704	2023-07-04	4	7	Q3	2023
20230705	2023-07-05	5	7	Q3	2023
20230706	2023-07-06	6	7	Q3	2023
20230707	2023-07-07	7	7	Q3	2023
20230708	2023-07-08	8	7	Q3	2023
20230709	2023-07-09	9	7	Q3	2023
20230710	2023-07-10	10	7	Q3	2023
20230711	2023-07-11	11	7	Q3	2023
20230712	2023-07-12	12	7	Q3	2023
20230713	2023-07-13	13	7	Q3	2023
20230714	2023-07-14	14	7	Q3	2023
20230715	2023-07-15	15	7	Q3	2023
20230716	2023-07-16	16	7	Q3	2023
20230717	2023-07-17	17	7	Q3	2023
20230718	2023-07-18	18	7	Q3	2023
20230719	2023-07-19	19	7	Q3	2023
20230720	2023-07-20	20	7	Q3	2023
20230721	2023-07-21	21	7	Q3	2023
20230722	2023-07-22	22	7	Q3	2023
20230723	2023-07-23	23	7	Q3	2023
20230724	2023-07-24	24	7	Q3	2023
20230725	2023-07-25	25	7	Q3	2023
20230726	2023-07-26	26	7	Q3	2023
20230727	2023-07-27	27	7	Q3	2023
20230728	2023-07-28	28	7	Q3	2023
20230729	2023-07-29	29	7	Q3	2023
20230730	2023-07-30	30	7	Q3	2023
20230731	2023-07-31	31	7	Q3	2023
20230801	2023-08-01	1	8	Q3	2023
20230802	2023-08-02	2	8	Q3	2023
20230803	2023-08-03	3	8	Q3	2023
20230804	2023-08-04	4	8	Q3	2023
20230805	2023-08-05	5	8	Q3	2023
20230806	2023-08-06	6	8	Q3	2023
20230807	2023-08-07	7	8	Q3	2023
20230808	2023-08-08	8	8	Q3	2023
20230809	2023-08-09	9	8	Q3	2023
20230810	2023-08-10	10	8	Q3	2023
20230811	2023-08-11	11	8	Q3	2023
20230812	2023-08-12	12	8	Q3	2023
20230813	2023-08-13	13	8	Q3	2023
20230814	2023-08-14	14	8	Q3	2023
20230815	2023-08-15	15	8	Q3	2023
20230816	2023-08-16	16	8	Q3	2023
20230817	2023-08-17	17	8	Q3	2023
20230818	2023-08-18	18	8	Q3	2023
20230819	2023-08-19	19	8	Q3	2023
20230820	2023-08-20	20	8	Q3	2023
20230821	2023-08-21	21	8	Q3	2023
20230822	2023-08-22	22	8	Q3	2023
20230823	2023-08-23	23	8	Q3	2023
20230824	2023-08-24	24	8	Q3	2023
20230825	2023-08-25	25	8	Q3	2023
20230826	2023-08-26	26	8	Q3	2023
20230827	2023-08-27	27	8	Q3	2023
20230828	2023-08-28	28	8	Q3	2023
20230829	2023-08-29	29	8	Q3	2023
20230830	2023-08-30	30	8	Q3	2023
20230831	2023-08-31	31	8	Q3	2023
20230901	2023-09-01	1	9	Q3	2023
20230902	2023-09-02	2	9	Q3	2023
20230903	2023-09-03	3	9	Q3	2023
20230904	2023-09-04	4	9	Q3	2023
20230905	2023-09-05	5	9	Q3	2023
20230906	2023-09-06	6	9	Q3	2023
20230907	2023-09-07	7	9	Q3	2023
20230908	2023-09-08	8	9	Q3	2023
20230909	2023-09-09	9	9	Q3	2023
20230910	2023-09-10	10	9	Q3	2023
20230911	2023-09-11	11	9	Q3	2023
20230912	2023-09-12	12	9	Q3	2023
20230913	2023-09-13	13	9	Q3	2023
20230914	2023-09-14	14	9	Q3	2023
20230915	2023-09-15	15	9	Q3	2023
20230916	2023-09-16	16	9	Q3	2023
20230917	2023-09-17	17	9	Q3	2023
20230918	2023-09-18	18	9	Q3	2023
20230919	2023-09-19	19	9	Q3	2023
20230920	2023-09-20	20	9	Q3	2023
20230921	2023-09-21	21	9	Q3	2023
20230922	2023-09-22	22	9	Q3	2023
20230923	2023-09-23	23	9	Q3	2023
20230924	2023-09-24	24	9	Q3	2023
20230925	2023-09-25	25	9	Q3	2023
20230926	2023-09-26	26	9	Q3	2023
20230927	2023-09-27	27	9	Q3	2023
20230928	2023-09-28	28	9	Q3	2023
20230929	2023-09-29	29	9	Q3	2023
20230930	2023-09-30	30	9	Q3	2023
20231001	2023-10-01	1	10	Q4	2023
20231002	2023-10-02	2	10	Q4	2023
20231003	2023-10-03	3	10	Q4	2023
20231004	2023-10-04	4	10	Q4	2023
20231005	2023-10-05	5	10	Q4	2023
20231006	2023-10-06	6	10	Q4	2023
20231007	2023-10-07	7	10	Q4	2023
20231008	2023-10-08	8	10	Q4	2023
20231009	2023-10-09	9	10	Q4	2023
20231010	2023-10-10	10	10	Q4	2023
20231011	2023-10-11	11	10	Q4	2023
20231012	2023-10-12	12	10	Q4	2023
20231013	2023-10-13	13	10	Q4	2023
20231014	2023-10-14	14	10	Q4	2023
20231015	2023-10-15	15	10	Q4	2023
20231016	2023-10-16	16	10	Q4	2023
20231017	2023-10-17	17	10	Q4	2023
20231018	2023-10-18	18	10	Q4	2023
20231019	2023-10-19	19	10	Q4	2023
20231020	2023-10-20	20	10	Q4	2023
20231021	2023-10-21	21	10	Q4	2023
20231022	2023-10-22	22	10	Q4	2023
20231023	2023-10-23	23	10	Q4	2023
20231024	2023-10-24	24	10	Q4	2023
20231025	2023-10-25	25	10	Q4	2023
20231026	2023-10-26	26	10	Q4	2023
20231027	2023-10-27	27	10	Q4	2023
20231028	2023-10-28	28	10	Q4	2023
20231029	2023-10-29	29	10	Q4	2023
20231030	2023-10-30	30	10	Q4	2023
20231031	2023-10-31	31	10	Q4	2023
20231101	2023-11-01	1	11	Q4	2023
20231102	2023-11-02	2	11	Q4	2023
20231103	2023-11-03	3	11	Q4	2023
20231104	2023-11-04	4	11	Q4	2023
20231105	2023-11-05	5	11	Q4	2023
20231106	2023-11-06	6	11	Q4	2023
20231107	2023-11-07	7	11	Q4	2023
20231108	2023-11-08	8	11	Q4	2023
20231109	2023-11-09	9	11	Q4	2023
20231110	2023-11-10	10	11	Q4	2023
20231111	2023-11-11	11	11	Q4	2023
20231112	2023-11-12	12	11	Q4	2023
20231113	2023-11-13	13	11	Q4	2023
20231114	2023-11-14	14	11	Q4	2023
20231115	2023-11-15	15	11	Q4	2023
20231116	2023-11-16	16	11	Q4	2023
20231117	2023-11-17	17	11	Q4	2023
20231118	2023-11-18	18	11	Q4	2023
20231119	2023-11-19	19	11	Q4	2023
20231120	2023-11-20	20	11	Q4	2023
20231121	2023-11-21	21	11	Q4	2023
20231122	2023-11-22	22	11	Q4	2023
20231123	2023-11-23	23	11	Q4	2023
20231124	2023-11-24	24	11	Q4	2023
20231125	2023-11-25	25	11	Q4	2023
20231126	2023-11-26	26	11	Q4	2023
20231127	2023-11-27	27	11	Q4	2023
20231128	2023-11-28	28	11	Q4	2023
20231129	2023-11-29	29	11	Q4	2023
20231130	2023-11-30	30	11	Q4	2023
20231201	2023-12-01	1	12	Q4	2023
20231202	2023-12-02	2	12	Q4	2023
20231203	2023-12-03	3	12	Q4	2023
20231204	2023-12-04	4	12	Q4	2023
20231205	2023-12-05	5	12	Q4	2023
20231206	2023-12-06	6	12	Q4	2023
20231207	2023-12-07	7	12	Q4	2023
20231208	2023-12-08	8	12	Q4	2023
20231209	2023-12-09	9	12	Q4	2023
20231210	2023-12-10	10	12	Q4	2023
20231211	2023-12-11	11	12	Q4	2023
20231212	2023-12-12	12	12	Q4	2023
20231213	2023-12-13	13	12	Q4	2023
20231214	2023-12-14	14	12	Q4	2023
20231215	2023-12-15	15	12	Q4	2023
20231216	2023-12-16	16	12	Q4	2023
20231217	2023-12-17	17	12	Q4	2023
20231218	2023-12-18	18	12	Q4	2023
20231219	2023-12-19	19	12	Q4	2023
20231220	2023-12-20	20	12	Q4	2023
20231221	2023-12-21	21	12	Q4	2023
20231222	2023-12-22	22	12	Q4	2023
20231223	2023-12-23	23	12	Q4	2023
20231224	2023-12-24	24	12	Q4	2023
20231225	2023-12-25	25	12	Q4	2023
20231226	2023-12-26	26	12	Q4	2023
20231227	2023-12-27	27	12	Q4	2023
20231228	2023-12-28	28	12	Q4	2023
20231229	2023-12-29	29	12	Q4	2023
20231230	2023-12-30	30	12	Q4	2023
20231231	2023-12-31	31	12	Q4	2023
20240101	2024-01-01	1	1	Q1	2024
20240102	2024-01-02	2	1	Q1	2024
20240103	2024-01-03	3	1	Q1	2024
20240104	2024-01-04	4	1	Q1	2024
20240105	2024-01-05	5	1	Q1	2024
20240106	2024-01-06	6	1	Q1	2024
20240107	2024-01-07	7	1	Q1	2024
20240108	2024-01-08	8	1	Q1	2024
20240109	2024-01-09	9	1	Q1	2024
20240110	2024-01-10	10	1	Q1	2024
20240111	2024-01-11	11	1	Q1	2024
20240112	2024-01-12	12	1	Q1	2024
20240113	2024-01-13	13	1	Q1	2024
20240114	2024-01-14	14	1	Q1	2024
20240115	2024-01-15	15	1	Q1	2024
20240116	2024-01-16	16	1	Q1	2024
20240117	2024-01-17	17	1	Q1	2024
20240118	2024-01-18	18	1	Q1	2024
20240119	2024-01-19	19	1	Q1	2024
20240120	2024-01-20	20	1	Q1	2024
20240121	2024-01-21	21	1	Q1	2024
20240122	2024-01-22	22	1	Q1	2024
20240123	2024-01-23	23	1	Q1	2024
20240124	2024-01-24	24	1	Q1	2024
20240125	2024-01-25	25	1	Q1	2024
20240126	2024-01-26	26	1	Q1	2024
20240127	2024-01-27	27	1	Q1	2024
20240128	2024-01-28	28	1	Q1	2024
20240129	2024-01-29	29	1	Q1	2024
20240130	2024-01-30	30	1	Q1	2024
20240131	2024-01-31	31	1	Q1	2024
20240201	2024-02-01	1	2	Q1	2024
20240202	2024-02-02	2	2	Q1	2024
20240203	2024-02-03	3	2	Q1	2024
20240204	2024-02-04	4	2	Q1	2024
20240205	2024-02-05	5	2	Q1	2024
20240206	2024-02-06	6	2	Q1	2024
20240207	2024-02-07	7	2	Q1	2024
20240208	2024-02-08	8	2	Q1	2024
20240209	2024-02-09	9	2	Q1	2024
20240210	2024-02-10	10	2	Q1	2024
20240211	2024-02-11	11	2	Q1	2024
20240212	2024-02-12	12	2	Q1	2024
20240213	2024-02-13	13	2	Q1	2024
20240214	2024-02-14	14	2	Q1	2024
20240215	2024-02-15	15	2	Q1	2024
20240216	2024-02-16	16	2	Q1	2024
20240217	2024-02-17	17	2	Q1	2024
20240218	2024-02-18	18	2	Q1	2024
20240219	2024-02-19	19	2	Q1	2024
20240220	2024-02-20	20	2	Q1	2024
20240221	2024-02-21	21	2	Q1	2024
20240222	2024-02-22	22	2	Q1	2024
20240223	2024-02-23	23	2	Q1	2024
20240224	2024-02-24	24	2	Q1	2024
20240225	2024-02-25	25	2	Q1	2024
20240226	2024-02-26	26	2	Q1	2024
20240227	2024-02-27	27	2	Q1	2024
20240228	2024-02-28	28	2	Q1	2024
20240229	2024-02-29	29	2	Q1	2024
20240301	2024-03-01	1	3	Q1	2024
20240302	2024-03-02	2	3	Q1	2024
20240303	2024-03-03	3	3	Q1	2024
20240304	2024-03-04	4	3	Q1	2024
20240305	2024-03-05	5	3	Q1	2024
20240306	2024-03-06	6	3	Q1	2024
20240307	2024-03-07	7	3	Q1	2024
20240308	2024-03-08	8	3	Q1	2024
20240309	2024-03-09	9	3	Q1	2024
20240310	2024-03-10	10	3	Q1	2024
20240311	2024-03-11	11	3	Q1	2024
20240312	2024-03-12	12	3	Q1	2024
20240313	2024-03-13	13	3	Q1	2024
20240314	2024-03-14	14	3	Q1	2024
20240315	2024-03-15	15	3	Q1	2024
20240316	2024-03-16	16	3	Q1	2024
20240317	2024-03-17	17	3	Q1	2024
20240318	2024-03-18	18	3	Q1	2024
20240319	2024-03-19	19	3	Q1	2024
20240320	2024-03-20	20	3	Q1	2024
20240321	2024-03-21	21	3	Q1	2024
20240322	2024-03-22	22	3	Q1	2024
20240323	2024-03-23	23	3	Q1	2024
20240324	2024-03-24	24	3	Q1	2024
20240325	2024-03-25	25	3	Q1	2024
20240326	2024-03-26	26	3	Q1	2024
20240327	2024-03-27	27	3	Q1	2024
20240328	2024-03-28	28	3	Q1	2024
20240329	2024-03-29	29	3	Q1	2024
20240330	2024-03-30	30	3	Q1	2024
20240331	2024-03-31	31	3	Q1	2024
20240401	2024-04-01	1	4	Q2	2024
20240402	2024-04-02	2	4	Q2	2024
20240403	2024-04-03	3	4	Q2	2024
20240404	2024-04-04	4	4	Q2	2024
20240405	2024-04-05	5	4	Q2	2024
20240406	2024-04-06	6	4	Q2	2024
20240407	2024-04-07	7	4	Q2	2024
20240408	2024-04-08	8	4	Q2	2024
20240409	2024-04-09	9	4	Q2	2024
20240410	2024-04-10	10	4	Q2	2024
20240411	2024-04-11	11	4	Q2	2024
20240412	2024-04-12	12	4	Q2	2024
20240413	2024-04-13	13	4	Q2	2024
20240414	2024-04-14	14	4	Q2	2024
20240415	2024-04-15	15	4	Q2	2024
20240416	2024-04-16	16	4	Q2	2024
20240417	2024-04-17	17	4	Q2	2024
20240418	2024-04-18	18	4	Q2	2024
20240419	2024-04-19	19	4	Q2	2024
20240420	2024-04-20	20	4	Q2	2024
20240421	2024-04-21	21	4	Q2	2024
20240422	2024-04-22	22	4	Q2	2024
20240423	2024-04-23	23	4	Q2	2024
20240424	2024-04-24	24	4	Q2	2024
20240425	2024-04-25	25	4	Q2	2024
20240426	2024-04-26	26	4	Q2	2024
20240427	2024-04-27	27	4	Q2	2024
20240428	2024-04-28	28	4	Q2	2024
20240429	2024-04-29	29	4	Q2	2024
20240430	2024-04-30	30	4	Q2	2024
20240501	2024-05-01	1	5	Q2	2024
20240502	2024-05-02	2	5	Q2	2024
20240503	2024-05-03	3	5	Q2	2024
20240504	2024-05-04	4	5	Q2	2024
20240505	2024-05-05	5	5	Q2	2024
20240506	2024-05-06	6	5	Q2	2024
20240507	2024-05-07	7	5	Q2	2024
20240508	2024-05-08	8	5	Q2	2024
20240509	2024-05-09	9	5	Q2	2024
20240510	2024-05-10	10	5	Q2	2024
20240511	2024-05-11	11	5	Q2	2024
20240512	2024-05-12	12	5	Q2	2024
20240513	2024-05-13	13	5	Q2	2024
20240514	2024-05-14	14	5	Q2	2024
20240515	2024-05-15	15	5	Q2	2024
20240516	2024-05-16	16	5	Q2	2024
20240517	2024-05-17	17	5	Q2	2024
20240518	2024-05-18	18	5	Q2	2024
20240519	2024-05-19	19	5	Q2	2024
20240520	2024-05-20	20	5	Q2	2024
20240521	2024-05-21	21	5	Q2	2024
20240522	2024-05-22	22	5	Q2	2024
20240523	2024-05-23	23	5	Q2	2024
20240524	2024-05-24	24	5	Q2	2024
20240525	2024-05-25	25	5	Q2	2024
20240526	2024-05-26	26	5	Q2	2024
20240527	2024-05-27	27	5	Q2	2024
20240528	2024-05-28	28	5	Q2	2024
20240529	2024-05-29	29	5	Q2	2024
20240530	2024-05-30	30	5	Q2	2024
20240531	2024-05-31	31	5	Q2	2024
20240601	2024-06-01	1	6	Q2	2024
20240602	2024-06-02	2	6	Q2	2024
20240603	2024-06-03	3	6	Q2	2024
20240604	2024-06-04	4	6	Q2	2024
20240605	2024-06-05	5	6	Q2	2024
20240606	2024-06-06	6	6	Q2	2024
20240607	2024-06-07	7	6	Q2	2024
20240608	2024-06-08	8	6	Q2	2024
20240609	2024-06-09	9	6	Q2	2024
20240610	2024-06-10	10	6	Q2	2024
20240611	2024-06-11	11	6	Q2	2024
20240612	2024-06-12	12	6	Q2	2024
20240613	2024-06-13	13	6	Q2	2024
20240614	2024-06-14	14	6	Q2	2024
20240615	2024-06-15	15	6	Q2	2024
20240616	2024-06-16	16	6	Q2	2024
20240617	2024-06-17	17	6	Q2	2024
20240618	2024-06-18	18	6	Q2	2024
20240619	2024-06-19	19	6	Q2	2024
20240620	2024-06-20	20	6	Q2	2024
20240621	2024-06-21	21	6	Q2	2024
20240622	2024-06-22	22	6	Q2	2024
20240623	2024-06-23	23	6	Q2	2024
20240624	2024-06-24	24	6	Q2	2024
20240625	2024-06-25	25	6	Q2	2024
20240626	2024-06-26	26	6	Q2	2024
20240627	2024-06-27	27	6	Q2	2024
20240628	2024-06-28	28	6	Q2	2024
20240629	2024-06-29	29	6	Q2	2024
20240630	2024-06-30	30	6	Q2	2024
20240701	2024-07-01	1	7	Q3	2024
20240702	2024-07-02	2	7	Q3	2024
20240703	2024-07-03	3	7	Q3	2024
20240704	2024-07-04	4	7	Q3	2024
20240705	2024-07-05	5	7	Q3	2024
20240706	2024-07-06	6	7	Q3	2024
20240707	2024-07-07	7	7	Q3	2024
20240708	2024-07-08	8	7	Q3	2024
20240709	2024-07-09	9	7	Q3	2024
20240710	2024-07-10	10	7	Q3	2024
20240711	2024-07-11	11	7	Q3	2024
20240712	2024-07-12	12	7	Q3	2024
20240713	2024-07-13	13	7	Q3	2024
20240714	2024-07-14	14	7	Q3	2024
20240715	2024-07-15	15	7	Q3	2024
20240716	2024-07-16	16	7	Q3	2024
20240717	2024-07-17	17	7	Q3	2024
20240718	2024-07-18	18	7	Q3	2024
20240719	2024-07-19	19	7	Q3	2024
20240720	2024-07-20	20	7	Q3	2024
20240721	2024-07-21	21	7	Q3	2024
20240722	2024-07-22	22	7	Q3	2024
20240723	2024-07-23	23	7	Q3	2024
20240724	2024-07-24	24	7	Q3	2024
20240725	2024-07-25	25	7	Q3	2024
20240726	2024-07-26	26	7	Q3	2024
20240727	2024-07-27	27	7	Q3	2024
20240728	2024-07-28	28	7	Q3	2024
20240729	2024-07-29	29	7	Q3	2024
20240730	2024-07-30	30	7	Q3	2024
20240731	2024-07-31	31	7	Q3	2024
20240801	2024-08-01	1	8	Q3	2024
20240802	2024-08-02	2	8	Q3	2024
20240803	2024-08-03	3	8	Q3	2024
20240804	2024-08-04	4	8	Q3	2024
20240805	2024-08-05	5	8	Q3	2024
20240806	2024-08-06	6	8	Q3	2024
20240807	2024-08-07	7	8	Q3	2024
20240808	2024-08-08	8	8	Q3	2024
20240809	2024-08-09	9	8	Q3	2024
20240810	2024-08-10	10	8	Q3	2024
20240811	2024-08-11	11	8	Q3	2024
20240812	2024-08-12	12	8	Q3	2024
20240813	2024-08-13	13	8	Q3	2024
20240814	2024-08-14	14	8	Q3	2024
20240815	2024-08-15	15	8	Q3	2024
20240816	2024-08-16	16	8	Q3	2024
20240817	2024-08-17	17	8	Q3	2024
20240818	2024-08-18	18	8	Q3	2024
20240819	2024-08-19	19	8	Q3	2024
20240820	2024-08-20	20	8	Q3	2024
20240821	2024-08-21	21	8	Q3	2024
20240822	2024-08-22	22	8	Q3	2024
20240823	2024-08-23	23	8	Q3	2024
20240824	2024-08-24	24	8	Q3	2024
20240825	2024-08-25	25	8	Q3	2024
20240826	2024-08-26	26	8	Q3	2024
20240827	2024-08-27	27	8	Q3	2024
20240828	2024-08-28	28	8	Q3	2024
20240829	2024-08-29	29	8	Q3	2024
20240830	2024-08-30	30	8	Q3	2024
20240831	2024-08-31	31	8	Q3	2024
20240901	2024-09-01	1	9	Q3	2024
20240902	2024-09-02	2	9	Q3	2024
20240903	2024-09-03	3	9	Q3	2024
20240904	2024-09-04	4	9	Q3	2024
20240905	2024-09-05	5	9	Q3	2024
20240906	2024-09-06	6	9	Q3	2024
20240907	2024-09-07	7	9	Q3	2024
20240908	2024-09-08	8	9	Q3	2024
20240909	2024-09-09	9	9	Q3	2024
20240910	2024-09-10	10	9	Q3	2024
20240911	2024-09-11	11	9	Q3	2024
20240912	2024-09-12	12	9	Q3	2024
20240913	2024-09-13	13	9	Q3	2024
20240914	2024-09-14	14	9	Q3	2024
20240915	2024-09-15	15	9	Q3	2024
20240916	2024-09-16	16	9	Q3	2024
20240917	2024-09-17	17	9	Q3	2024
20240918	2024-09-18	18	9	Q3	2024
20240919	2024-09-19	19	9	Q3	2024
20240920	2024-09-20	20	9	Q3	2024
20240921	2024-09-21	21	9	Q3	2024
20240922	2024-09-22	22	9	Q3	2024
20240923	2024-09-23	23	9	Q3	2024
20240924	2024-09-24	24	9	Q3	2024
20240925	2024-09-25	25	9	Q3	2024
20240926	2024-09-26	26	9	Q3	2024
20240927	2024-09-27	27	9	Q3	2024
20240928	2024-09-28	28	9	Q3	2024
20240929	2024-09-29	29	9	Q3	2024
20240930	2024-09-30	30	9	Q3	2024
20241001	2024-10-01	1	10	Q4	2024
20241002	2024-10-02	2	10	Q4	2024
20241003	2024-10-03	3	10	Q4	2024
20241004	2024-10-04	4	10	Q4	2024
20241005	2024-10-05	5	10	Q4	2024
20241006	2024-10-06	6	10	Q4	2024
20241007	2024-10-07	7	10	Q4	2024
20241008	2024-10-08	8	10	Q4	2024
20241009	2024-10-09	9	10	Q4	2024
20241010	2024-10-10	10	10	Q4	2024
20241011	2024-10-11	11	10	Q4	2024
20241012	2024-10-12	12	10	Q4	2024
20241013	2024-10-13	13	10	Q4	2024
20241014	2024-10-14	14	10	Q4	2024
20241015	2024-10-15	15	10	Q4	2024
20241016	2024-10-16	16	10	Q4	2024
20241017	2024-10-17	17	10	Q4	2024
20241018	2024-10-18	18	10	Q4	2024
20241019	2024-10-19	19	10	Q4	2024
20241020	2024-10-20	20	10	Q4	2024
20241021	2024-10-21	21	10	Q4	2024
20241022	2024-10-22	22	10	Q4	2024
20241023	2024-10-23	23	10	Q4	2024
20241024	2024-10-24	24	10	Q4	2024
20241025	2024-10-25	25	10	Q4	2024
20241026	2024-10-26	26	10	Q4	2024
20241027	2024-10-27	27	10	Q4	2024
20241028	2024-10-28	28	10	Q4	2024
20241029	2024-10-29	29	10	Q4	2024
20241030	2024-10-30	30	10	Q4	2024
20241031	2024-10-31	31	10	Q4	2024
20241101	2024-11-01	1	11	Q4	2024
20241102	2024-11-02	2	11	Q4	2024
20241103	2024-11-03	3	11	Q4	2024
20241104	2024-11-04	4	11	Q4	2024
20241105	2024-11-05	5	11	Q4	2024
20241106	2024-11-06	6	11	Q4	2024
20241107	2024-11-07	7	11	Q4	2024
20241108	2024-11-08	8	11	Q4	2024
20241109	2024-11-09	9	11	Q4	2024
20241110	2024-11-10	10	11	Q4	2024
20241111	2024-11-11	11	11	Q4	2024
20241112	2024-11-12	12	11	Q4	2024
20241113	2024-11-13	13	11	Q4	2024
20241114	2024-11-14	14	11	Q4	2024
20241115	2024-11-15	15	11	Q4	2024
20241116	2024-11-16	16	11	Q4	2024
20241117	2024-11-17	17	11	Q4	2024
20241118	2024-11-18	18	11	Q4	2024
20241119	2024-11-19	19	11	Q4	2024
20241120	2024-11-20	20	11	Q4	2024
20241121	2024-11-21	21	11	Q4	2024
20241122	2024-11-22	22	11	Q4	2024
20241123	2024-11-23	23	11	Q4	2024
20241124	2024-11-24	24	11	Q4	2024
20241125	2024-11-25	25	11	Q4	2024
20241126	2024-11-26	26	11	Q4	2024
20241127	2024-11-27	27	11	Q4	2024
20241128	2024-11-28	28	11	Q4	2024
20241129	2024-11-29	29	11	Q4	2024
20241130	2024-11-30	30	11	Q4	2024
20241201	2024-12-01	1	12	Q4	2024
20241202	2024-12-02	2	12	Q4	2024
20241203	2024-12-03	3	12	Q4	2024
20241204	2024-12-04	4	12	Q4	2024
20241205	2024-12-05	5	12	Q4	2024
20241206	2024-12-06	6	12	Q4	2024
20241207	2024-12-07	7	12	Q4	2024
20241208	2024-12-08	8	12	Q4	2024
20241209	2024-12-09	9	12	Q4	2024
20241210	2024-12-10	10	12	Q4	2024
20241211	2024-12-11	11	12	Q4	2024
20241212	2024-12-12	12	12	Q4	2024
20241213	2024-12-13	13	12	Q4	2024
20241214	2024-12-14	14	12	Q4	2024
20241215	2024-12-15	15	12	Q4	2024
20241216	2024-12-16	16	12	Q4	2024
20241217	2024-12-17	17	12	Q4	2024
20241218	2024-12-18	18	12	Q4	2024
20241219	2024-12-19	19	12	Q4	2024
20241220	2024-12-20	20	12	Q4	2024
20241221	2024-12-21	21	12	Q4	2024
20241222	2024-12-22	22	12	Q4	2024
20241223	2024-12-23	23	12	Q4	2024
20241224	2024-12-24	24	12	Q4	2024
20241225	2024-12-25	25	12	Q4	2024
20241226	2024-12-26	26	12	Q4	2024
20241227	2024-12-27	27	12	Q4	2024
20241228	2024-12-28	28	12	Q4	2024
20241229	2024-12-29	29	12	Q4	2024
20241230	2024-12-30	30	12	Q4	2024
20241231	2024-12-31	31	12	Q4	2024
20250101	2025-01-01	1	1	Q1	2025
20250102	2025-01-02	2	1	Q1	2025
20250103	2025-01-03	3	1	Q1	2025
20250104	2025-01-04	4	1	Q1	2025
20250105	2025-01-05	5	1	Q1	2025
20250106	2025-01-06	6	1	Q1	2025
20250107	2025-01-07	7	1	Q1	2025
20250108	2025-01-08	8	1	Q1	2025
20250109	2025-01-09	9	1	Q1	2025
20250110	2025-01-10	10	1	Q1	2025
20250111	2025-01-11	11	1	Q1	2025
20250112	2025-01-12	12	1	Q1	2025
20250113	2025-01-13	13	1	Q1	2025
20250114	2025-01-14	14	1	Q1	2025
20250115	2025-01-15	15	1	Q1	2025
20250116	2025-01-16	16	1	Q1	2025
20250117	2025-01-17	17	1	Q1	2025
20250118	2025-01-18	18	1	Q1	2025
20250119	2025-01-19	19	1	Q1	2025
20250120	2025-01-20	20	1	Q1	2025
20250121	2025-01-21	21	1	Q1	2025
20250122	2025-01-22	22	1	Q1	2025
20250123	2025-01-23	23	1	Q1	2025
20250124	2025-01-24	24	1	Q1	2025
20250125	2025-01-25	25	1	Q1	2025
20250126	2025-01-26	26	1	Q1	2025
20250127	2025-01-27	27	1	Q1	2025
20250128	2025-01-28	28	1	Q1	2025
20250129	2025-01-29	29	1	Q1	2025
20250130	2025-01-30	30	1	Q1	2025
20250131	2025-01-31	31	1	Q1	2025
20250201	2025-02-01	1	2	Q1	2025
20250202	2025-02-02	2	2	Q1	2025
20250203	2025-02-03	3	2	Q1	2025
20250204	2025-02-04	4	2	Q1	2025
20250205	2025-02-05	5	2	Q1	2025
20250206	2025-02-06	6	2	Q1	2025
20250207	2025-02-07	7	2	Q1	2025
20250208	2025-02-08	8	2	Q1	2025
20250209	2025-02-09	9	2	Q1	2025
20250210	2025-02-10	10	2	Q1	2025
20250211	2025-02-11	11	2	Q1	2025
20250212	2025-02-12	12	2	Q1	2025
20250213	2025-02-13	13	2	Q1	2025
20250214	2025-02-14	14	2	Q1	2025
20250215	2025-02-15	15	2	Q1	2025
20250216	2025-02-16	16	2	Q1	2025
20250217	2025-02-17	17	2	Q1	2025
20250218	2025-02-18	18	2	Q1	2025
20250219	2025-02-19	19	2	Q1	2025
20250220	2025-02-20	20	2	Q1	2025
20250221	2025-02-21	21	2	Q1	2025
20250222	2025-02-22	22	2	Q1	2025
20250223	2025-02-23	23	2	Q1	2025
20250224	2025-02-24	24	2	Q1	2025
20250225	2025-02-25	25	2	Q1	2025
20250226	2025-02-26	26	2	Q1	2025
20250227	2025-02-27	27	2	Q1	2025
20250228	2025-02-28	28	2	Q1	2025
20250301	2025-03-01	1	3	Q1	2025
20250302	2025-03-02	2	3	Q1	2025
20250303	2025-03-03	3	3	Q1	2025
20250304	2025-03-04	4	3	Q1	2025
20250305	2025-03-05	5	3	Q1	2025
20250306	2025-03-06	6	3	Q1	2025
20250307	2025-03-07	7	3	Q1	2025
20250308	2025-03-08	8	3	Q1	2025
20250309	2025-03-09	9	3	Q1	2025
20250310	2025-03-10	10	3	Q1	2025
20250311	2025-03-11	11	3	Q1	2025
20250312	2025-03-12	12	3	Q1	2025
20250313	2025-03-13	13	3	Q1	2025
20250314	2025-03-14	14	3	Q1	2025
20250315	2025-03-15	15	3	Q1	2025
20250316	2025-03-16	16	3	Q1	2025
20250317	2025-03-17	17	3	Q1	2025
20250318	2025-03-18	18	3	Q1	2025
20250319	2025-03-19	19	3	Q1	2025
20250320	2025-03-20	20	3	Q1	2025
20250321	2025-03-21	21	3	Q1	2025
20250322	2025-03-22	22	3	Q1	2025
20250323	2025-03-23	23	3	Q1	2025
20250324	2025-03-24	24	3	Q1	2025
20250325	2025-03-25	25	3	Q1	2025
20250326	2025-03-26	26	3	Q1	2025
20250327	2025-03-27	27	3	Q1	2025
20250328	2025-03-28	28	3	Q1	2025
20250329	2025-03-29	29	3	Q1	2025
20250330	2025-03-30	30	3	Q1	2025
20250331	2025-03-31	31	3	Q1	2025
20250401	2025-04-01	1	4	Q2	2025
20250402	2025-04-02	2	4	Q2	2025
20250403	2025-04-03	3	4	Q2	2025
20250404	2025-04-04	4	4	Q2	2025
20250405	2025-04-05	5	4	Q2	2025
20250406	2025-04-06	6	4	Q2	2025
20250407	2025-04-07	7	4	Q2	2025
20250408	2025-04-08	8	4	Q2	2025
20250409	2025-04-09	9	4	Q2	2025
20250410	2025-04-10	10	4	Q2	2025
20250411	2025-04-11	11	4	Q2	2025
20250412	2025-04-12	12	4	Q2	2025
20250413	2025-04-13	13	4	Q2	2025
20250414	2025-04-14	14	4	Q2	2025
20250415	2025-04-15	15	4	Q2	2025
20250416	2025-04-16	16	4	Q2	2025
20250417	2025-04-17	17	4	Q2	2025
20250418	2025-04-18	18	4	Q2	2025
20250419	2025-04-19	19	4	Q2	2025
20250420	2025-04-20	20	4	Q2	2025
20250421	2025-04-21	21	4	Q2	2025
20250422	2025-04-22	22	4	Q2	2025
20250423	2025-04-23	23	4	Q2	2025
20250424	2025-04-24	24	4	Q2	2025
20250425	2025-04-25	25	4	Q2	2025
20250426	2025-04-26	26	4	Q2	2025
20250427	2025-04-27	27	4	Q2	2025
20250428	2025-04-28	28	4	Q2	2025
20250429	2025-04-29	29	4	Q2	2025
20250430	2025-04-30	30	4	Q2	2025
20250501	2025-05-01	1	5	Q2	2025
20250502	2025-05-02	2	5	Q2	2025
20250503	2025-05-03	3	5	Q2	2025
20250504	2025-05-04	4	5	Q2	2025
20250505	2025-05-05	5	5	Q2	2025
20250506	2025-05-06	6	5	Q2	2025
20250507	2025-05-07	7	5	Q2	2025
20250508	2025-05-08	8	5	Q2	2025
20250509	2025-05-09	9	5	Q2	2025
20250510	2025-05-10	10	5	Q2	2025
20250511	2025-05-11	11	5	Q2	2025
20250512	2025-05-12	12	5	Q2	2025
20250513	2025-05-13	13	5	Q2	2025
20250514	2025-05-14	14	5	Q2	2025
20250515	2025-05-15	15	5	Q2	2025
20250516	2025-05-16	16	5	Q2	2025
20250517	2025-05-17	17	5	Q2	2025
20250518	2025-05-18	18	5	Q2	2025
20250519	2025-05-19	19	5	Q2	2025
20250520	2025-05-20	20	5	Q2	2025
20250521	2025-05-21	21	5	Q2	2025
20250522	2025-05-22	22	5	Q2	2025
20250523	2025-05-23	23	5	Q2	2025
20250524	2025-05-24	24	5	Q2	2025
20250525	2025-05-25	25	5	Q2	2025
20250526	2025-05-26	26	5	Q2	2025
20250527	2025-05-27	27	5	Q2	2025
20250528	2025-05-28	28	5	Q2	2025
20250529	2025-05-29	29	5	Q2	2025
20250530	2025-05-30	30	5	Q2	2025
20250531	2025-05-31	31	5	Q2	2025
20250601	2025-06-01	1	6	Q2	2025
20250602	2025-06-02	2	6	Q2	2025
20250603	2025-06-03	3	6	Q2	2025
20250604	2025-06-04	4	6	Q2	2025
20250605	2025-06-05	5	6	Q2	2025
20250606	2025-06-06	6	6	Q2	2025
20250607	2025-06-07	7	6	Q2	2025
20250608	2025-06-08	8	6	Q2	2025
20250609	2025-06-09	9	6	Q2	2025
20250610	2025-06-10	10	6	Q2	2025
20250611	2025-06-11	11	6	Q2	2025
20250612	2025-06-12	12	6	Q2	2025
20250613	2025-06-13	13	6	Q2	2025
20250614	2025-06-14	14	6	Q2	2025
20250615	2025-06-15	15	6	Q2	2025
20250616	2025-06-16	16	6	Q2	2025
20250617	2025-06-17	17	6	Q2	2025
20250618	2025-06-18	18	6	Q2	2025
20250619	2025-06-19	19	6	Q2	2025
20250620	2025-06-20	20	6	Q2	2025
20250621	2025-06-21	21	6	Q2	2025
20250622	2025-06-22	22	6	Q2	2025
20250623	2025-06-23	23	6	Q2	2025
20250624	2025-06-24	24	6	Q2	2025
20250625	2025-06-25	25	6	Q2	2025
20250626	2025-06-26	26	6	Q2	2025
20250627	2025-06-27	27	6	Q2	2025
20250628	2025-06-28	28	6	Q2	2025
20250629	2025-06-29	29	6	Q2	2025
20250630	2025-06-30	30	6	Q2	2025
20250701	2025-07-01	1	7	Q3	2025
20250702	2025-07-02	2	7	Q3	2025
20250703	2025-07-03	3	7	Q3	2025
20250704	2025-07-04	4	7	Q3	2025
20250705	2025-07-05	5	7	Q3	2025
20250706	2025-07-06	6	7	Q3	2025
20250707	2025-07-07	7	7	Q3	2025
20250708	2025-07-08	8	7	Q3	2025
20250709	2025-07-09	9	7	Q3	2025
20250710	2025-07-10	10	7	Q3	2025
20250711	2025-07-11	11	7	Q3	2025
20250712	2025-07-12	12	7	Q3	2025
20250713	2025-07-13	13	7	Q3	2025
20250714	2025-07-14	14	7	Q3	2025
20250715	2025-07-15	15	7	Q3	2025
20250716	2025-07-16	16	7	Q3	2025
20250717	2025-07-17	17	7	Q3	2025
20250718	2025-07-18	18	7	Q3	2025
20250719	2025-07-19	19	7	Q3	2025
20250720	2025-07-20	20	7	Q3	2025
20250721	2025-07-21	21	7	Q3	2025
20250722	2025-07-22	22	7	Q3	2025
20250723	2025-07-23	23	7	Q3	2025
20250724	2025-07-24	24	7	Q3	2025
20250725	2025-07-25	25	7	Q3	2025
20250726	2025-07-26	26	7	Q3	2025
20250727	2025-07-27	27	7	Q3	2025
20250728	2025-07-28	28	7	Q3	2025
20250729	2025-07-29	29	7	Q3	2025
20250730	2025-07-30	30	7	Q3	2025
20250731	2025-07-31	31	7	Q3	2025
20250801	2025-08-01	1	8	Q3	2025
20250802	2025-08-02	2	8	Q3	2025
20250803	2025-08-03	3	8	Q3	2025
20250804	2025-08-04	4	8	Q3	2025
20250805	2025-08-05	5	8	Q3	2025
20250806	2025-08-06	6	8	Q3	2025
20250807	2025-08-07	7	8	Q3	2025
20250808	2025-08-08	8	8	Q3	2025
20250809	2025-08-09	9	8	Q3	2025
20250810	2025-08-10	10	8	Q3	2025
20250811	2025-08-11	11	8	Q3	2025
20250812	2025-08-12	12	8	Q3	2025
20250813	2025-08-13	13	8	Q3	2025
20250814	2025-08-14	14	8	Q3	2025
20250815	2025-08-15	15	8	Q3	2025
20250816	2025-08-16	16	8	Q3	2025
20250817	2025-08-17	17	8	Q3	2025
20250818	2025-08-18	18	8	Q3	2025
20250819	2025-08-19	19	8	Q3	2025
20250820	2025-08-20	20	8	Q3	2025
20250821	2025-08-21	21	8	Q3	2025
20250822	2025-08-22	22	8	Q3	2025
20250823	2025-08-23	23	8	Q3	2025
20250824	2025-08-24	24	8	Q3	2025
20250825	2025-08-25	25	8	Q3	2025
20250826	2025-08-26	26	8	Q3	2025
20250827	2025-08-27	27	8	Q3	2025
20250828	2025-08-28	28	8	Q3	2025
20250829	2025-08-29	29	8	Q3	2025
20250830	2025-08-30	30	8	Q3	2025
20250831	2025-08-31	31	8	Q3	2025
20250901	2025-09-01	1	9	Q3	2025
20250902	2025-09-02	2	9	Q3	2025
20250903	2025-09-03	3	9	Q3	2025
20250904	2025-09-04	4	9	Q3	2025
20250905	2025-09-05	5	9	Q3	2025
20250906	2025-09-06	6	9	Q3	2025
20250907	2025-09-07	7	9	Q3	2025
20250908	2025-09-08	8	9	Q3	2025
20250909	2025-09-09	9	9	Q3	2025
20250910	2025-09-10	10	9	Q3	2025
20250911	2025-09-11	11	9	Q3	2025
20250912	2025-09-12	12	9	Q3	2025
20250913	2025-09-13	13	9	Q3	2025
20250914	2025-09-14	14	9	Q3	2025
20250915	2025-09-15	15	9	Q3	2025
20250916	2025-09-16	16	9	Q3	2025
20250917	2025-09-17	17	9	Q3	2025
20250918	2025-09-18	18	9	Q3	2025
20250919	2025-09-19	19	9	Q3	2025
20250920	2025-09-20	20	9	Q3	2025
20250921	2025-09-21	21	9	Q3	2025
20250922	2025-09-22	22	9	Q3	2025
20250923	2025-09-23	23	9	Q3	2025
20250924	2025-09-24	24	9	Q3	2025
20250925	2025-09-25	25	9	Q3	2025
20250926	2025-09-26	26	9	Q3	2025
20250927	2025-09-27	27	9	Q3	2025
20250928	2025-09-28	28	9	Q3	2025
20250929	2025-09-29	29	9	Q3	2025
20250930	2025-09-30	30	9	Q3	2025
20251001	2025-10-01	1	10	Q4	2025
20251002	2025-10-02	2	10	Q4	2025
20251003	2025-10-03	3	10	Q4	2025
20251004	2025-10-04	4	10	Q4	2025
20251005	2025-10-05	5	10	Q4	2025
20251006	2025-10-06	6	10	Q4	2025
20251007	2025-10-07	7	10	Q4	2025
20251008	2025-10-08	8	10	Q4	2025
20251009	2025-10-09	9	10	Q4	2025
20251010	2025-10-10	10	10	Q4	2025
20251011	2025-10-11	11	10	Q4	2025
20251012	2025-10-12	12	10	Q4	2025
20251013	2025-10-13	13	10	Q4	2025
20251014	2025-10-14	14	10	Q4	2025
20251015	2025-10-15	15	10	Q4	2025
20251016	2025-10-16	16	10	Q4	2025
20251017	2025-10-17	17	10	Q4	2025
20251018	2025-10-18	18	10	Q4	2025
20251019	2025-10-19	19	10	Q4	2025
20251020	2025-10-20	20	10	Q4	2025
20251021	2025-10-21	21	10	Q4	2025
20251022	2025-10-22	22	10	Q4	2025
20251023	2025-10-23	23	10	Q4	2025
20251024	2025-10-24	24	10	Q4	2025
20251025	2025-10-25	25	10	Q4	2025
20251026	2025-10-26	26	10	Q4	2025
20251027	2025-10-27	27	10	Q4	2025
20251028	2025-10-28	28	10	Q4	2025
20251029	2025-10-29	29	10	Q4	2025
20251030	2025-10-30	30	10	Q4	2025
20251031	2025-10-31	31	10	Q4	2025
20251101	2025-11-01	1	11	Q4	2025
20251102	2025-11-02	2	11	Q4	2025
20251103	2025-11-03	3	11	Q4	2025
20251104	2025-11-04	4	11	Q4	2025
20251105	2025-11-05	5	11	Q4	2025
20251106	2025-11-06	6	11	Q4	2025
20251107	2025-11-07	7	11	Q4	2025
20251108	2025-11-08	8	11	Q4	2025
20251109	2025-11-09	9	11	Q4	2025
20251110	2025-11-10	10	11	Q4	2025
20251111	2025-11-11	11	11	Q4	2025
20251112	2025-11-12	12	11	Q4	2025
20251113	2025-11-13	13	11	Q4	2025
20251114	2025-11-14	14	11	Q4	2025
20251115	2025-11-15	15	11	Q4	2025
20251116	2025-11-16	16	11	Q4	2025
20251117	2025-11-17	17	11	Q4	2025
20251118	2025-11-18	18	11	Q4	2025
20251119	2025-11-19	19	11	Q4	2025
20251120	2025-11-20	20	11	Q4	2025
20251121	2025-11-21	21	11	Q4	2025
20251122	2025-11-22	22	11	Q4	2025
20251123	2025-11-23	23	11	Q4	2025
20251124	2025-11-24	24	11	Q4	2025
20251125	2025-11-25	25	11	Q4	2025
20251126	2025-11-26	26	11	Q4	2025
20251127	2025-11-27	27	11	Q4	2025
20251128	2025-11-28	28	11	Q4	2025
20251129	2025-11-29	29	11	Q4	2025
20251130	2025-11-30	30	11	Q4	2025
20251201	2025-12-01	1	12	Q4	2025
20251202	2025-12-02	2	12	Q4	2025
20251203	2025-12-03	3	12	Q4	2025
20251204	2025-12-04	4	12	Q4	2025
20251205	2025-12-05	5	12	Q4	2025
20251206	2025-12-06	6	12	Q4	2025
20251207	2025-12-07	7	12	Q4	2025
20251208	2025-12-08	8	12	Q4	2025
20251209	2025-12-09	9	12	Q4	2025
20251210	2025-12-10	10	12	Q4	2025
20251211	2025-12-11	11	12	Q4	2025
20251212	2025-12-12	12	12	Q4	2025
20251213	2025-12-13	13	12	Q4	2025
20251214	2025-12-14	14	12	Q4	2025
20251215	2025-12-15	15	12	Q4	2025
20251216	2025-12-16	16	12	Q4	2025
20251217	2025-12-17	17	12	Q4	2025
20251218	2025-12-18	18	12	Q4	2025
20251219	2025-12-19	19	12	Q4	2025
20251220	2025-12-20	20	12	Q4	2025
20251221	2025-12-21	21	12	Q4	2025
20251222	2025-12-22	22	12	Q4	2025
20251223	2025-12-23	23	12	Q4	2025
20251224	2025-12-24	24	12	Q4	2025
20251225	2025-12-25	25	12	Q4	2025
20251226	2025-12-26	26	12	Q4	2025
20251227	2025-12-27	27	12	Q4	2025
20251228	2025-12-28	28	12	Q4	2025
20251229	2025-12-29	29	12	Q4	2025
20251230	2025-12-30	30	12	Q4	2025
20251231	2025-12-31	31	12	Q4	2025
20260101	2026-01-01	1	1	Q1	2026
20260102	2026-01-02	2	1	Q1	2026
20260103	2026-01-03	3	1	Q1	2026
20260104	2026-01-04	4	1	Q1	2026
20260105	2026-01-05	5	1	Q1	2026
20260106	2026-01-06	6	1	Q1	2026
20260107	2026-01-07	7	1	Q1	2026
20260108	2026-01-08	8	1	Q1	2026
20260109	2026-01-09	9	1	Q1	2026
20260110	2026-01-10	10	1	Q1	2026
20260111	2026-01-11	11	1	Q1	2026
20260112	2026-01-12	12	1	Q1	2026
20260113	2026-01-13	13	1	Q1	2026
20260114	2026-01-14	14	1	Q1	2026
20260115	2026-01-15	15	1	Q1	2026
20260116	2026-01-16	16	1	Q1	2026
20260117	2026-01-17	17	1	Q1	2026
20260118	2026-01-18	18	1	Q1	2026
20260119	2026-01-19	19	1	Q1	2026
20260120	2026-01-20	20	1	Q1	2026
20260121	2026-01-21	21	1	Q1	2026
20260122	2026-01-22	22	1	Q1	2026
20260123	2026-01-23	23	1	Q1	2026
20260124	2026-01-24	24	1	Q1	2026
20260125	2026-01-25	25	1	Q1	2026
20260126	2026-01-26	26	1	Q1	2026
20260127	2026-01-27	27	1	Q1	2026
20260128	2026-01-28	28	1	Q1	2026
20260129	2026-01-29	29	1	Q1	2026
20260130	2026-01-30	30	1	Q1	2026
20260131	2026-01-31	31	1	Q1	2026
20260201	2026-02-01	1	2	Q1	2026
20260202	2026-02-02	2	2	Q1	2026
20260203	2026-02-03	3	2	Q1	2026
20260204	2026-02-04	4	2	Q1	2026
20260205	2026-02-05	5	2	Q1	2026
20260206	2026-02-06	6	2	Q1	2026
20260207	2026-02-07	7	2	Q1	2026
20260208	2026-02-08	8	2	Q1	2026
\.


--
-- Data for Name: fact_assignment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fact_assignment (sk_assignment, sk_employee, sk_project, sk_task, sk_branch, sk_time, planned_hours, actual_hours, utilization_rate, efficiency_score, assignment_cost, assignment_status) FROM stdin;
1	18	31	9	5	20240308	22.60	19.10	84.51327433628319	306.80628272251306	84384510	Paused
2	166	27	96	7	20250522	70.90	82.40	116.22002820874471	112.86407766990291	185804259	Completed
3	21	35	35	11	20250723	18.30	89.40	488.5245901639344	45.19015659955257	68547925	Completed
4	136	9	187	4	20250116	10.20	9.90	97.05882352941177	1134.3434343434344	125611604	Completed
5	119	35	109	9	20250808	67.60	28.30	41.86390532544379	80.91872791519434	68547925	Completed
6	40	18	49	12	20250130	12.30	62.10	504.8780487804878	31.40096618357488	80551177	Paused
7	5	16	53	2	20250130	51.60	44.60	86.43410852713178	234.97757847533632	199150873	Paused
8	13	16	190	1	20250417	40.70	52.30	128.5012285012285	117.01720841300192	199150873	Active
9	36	33	75	4	20240408	50.40	71.30	141.46825396825398	160.0280504908836	11994519	Completed
10	61	20	225	3	20241231	46.50	41.90	90.10752688172043	192.36276849642005	168452858	Completed
11	16	12	161	11	20250113	48.90	11.80	24.130879345603272	911.864406779661	191894786	Completed
12	165	25	202	9	20250519	58.70	41.50	70.69846678023849	71.08433734939759	28760553	Completed
13	97	12	194	9	20250119	26.90	26.50	98.51301115241637	377.35849056603774	191894786	Paused
14	37	30	235	1	20230517	77.70	53.70	69.1119691119691	99.4413407821229	353325145	Active
15	100	16	66	4	20250330	55.30	83.60	151.1754068716094	113.2775119617225	199150873	Completed
16	24	35	186	4	20250221	28.80	63.20	219.44444444444443	104.74683544303797	68547925	Paused
17	11	5	49	10	20231221	25.20	25.10	99.60317460317461	77.68924302788844	87392849	Completed
18	78	1	55	4	20251114	18.20	90.00	494.50549450549454	108	69934576	Completed
19	63	14	102	4	20250503	32.50	31.20	96	283.65384615384613	202714730	Completed
20	137	23	79	5	20250525	45.90	48.80	106.31808278867102	51.84426229508197	214561504	Active
21	121	21	235	4	20230513	31.90	11.70	36.677115987460816	456.41025641025647	131125964	Active
22	38	2	67	9	20250817	50.50	42.20	83.56435643564356	36.49289099526066	182752899	Active
23	51	22	59	7	20250413	68.30	48.90	71.59590043923866	149.28425357873212	27747514	Paused
24	176	22	66	8	20251102	60.60	68.60	113.20132013201318	138.0466472303207	27747514	Completed
25	44	23	44	3	20251125	48.30	23.10	47.82608695652174	320.34632034632034	214561504	Paused
26	165	4	135	1	20240603	69.30	85.50	123.37662337662339	77.19298245614036	188238298	Paused
27	13	1	106	3	20250918	26.20	66.00	251.9083969465649	160.3030303030303	69934576	Active
28	56	33	117	6	20230718	53.20	62.70	117.85714285714285	34.92822966507177	11994519	Paused
29	124	32	5	1	20250408	48.60	9.00	18.51851851851852	431.1111111111111	48839383	Paused
30	71	35	74	1	20251010	66.90	63.30	94.61883408071748	76.77725118483413	68547925	Active
31	28	7	135	3	20250309	23.40	51.20	218.80341880341882	128.90625	87142713	Completed
32	69	26	21	6	20250327	42.10	27.90	66.270783847981	259.13978494623655	82834081	Paused
33	58	20	176	2	20241229	79.40	61.30	77.20403022670024	64.43719412724307	168452858	Active
34	24	26	98	7	20250414	13.90	8.80	63.309352517985616	1153.4090909090908	82834081	Active
35	22	32	217	7	20241226	49.60	78.40	158.06451612903228	102.42346938775509	48839383	Active
36	136	3	59	4	20240425	58.50	54.50	93.16239316239316	133.94495412844037	263927189	Completed
37	12	5	176	5	20231213	49.40	10.70	21.65991902834008	369.15887850467294	87392849	Completed
38	5	14	151	3	20250623	67.40	75.30	111.72106824925815	75.03320053120851	202714730	Active
39	77	11	145	4	20241204	68.40	39.90	58.33333333333333	191.7293233082707	133788987	Paused
40	85	25	194	12	20250403	65.30	64.50	98.77488514548239	155.03875968992247	28760553	Active
41	129	23	14	2	20250703	26.30	14.20	53.99239543726235	132.3943661971831	214561504	Paused
42	158	26	249	6	20241221	54.40	72.30	132.90441176470588	18.118948824343015	82834081	Completed
43	126	15	92	9	20231125	40.20	63.70	158.45771144278606	100.78492935635792	47978853	Paused
44	98	6	198	10	20250126	65.90	66.50	100.91047040971168	130.82706766917292	53118958	Active
45	69	10	98	12	20250522	20.80	39.90	191.82692307692307	254.3859649122807	33497411	Completed
46	28	6	2	5	20250412	35.20	30.10	85.51136363636363	341.86046511627904	53118958	Active
47	23	12	111	8	20250130	48.80	41.50	85.04098360655738	189.87951807228916	191894786	Active
48	23	23	142	2	20250923	51.90	34.60	66.66666666666667	187.86127167630056	214561504	Completed
49	4	19	106	7	20250112	60.70	53.90	88.79736408566721	196.28942486085344	299592333	Active
50	147	34	44	11	20221217	21.90	30.10	137.44292237442923	245.8471760797342	109551712	Completed
51	127	10	17	3	20250509	29.30	32.60	111.26279863481228	357.36196319018404	33497411	Active
52	93	17	242	4	20250518	51.60	24.00	46.51162790697674	62.083333333333336	62164487	Active
53	35	20	2	7	20241008	68.90	39.20	56.89404934687954	262.5	168452858	Completed
54	113	22	111	11	20250426	19.50	34.30	175.89743589743588	229.7376093294461	27747514	Paused
55	52	31	81	3	20240302	77.80	31.90	41.0025706940874	239.49843260188092	84384510	Paused
56	163	32	248	10	20241111	32.80	31.00	94.51219512195122	168.70967741935485	48839383	Completed
57	94	8	239	10	20250201	51.50	52.70	102.33009708737865	164.32637571157494	99316412	Paused
58	141	2	244	12	20250615	76.00	25.20	33.1578947368421	334.12698412698415	182752899	Completed
59	178	5	210	7	20231120	19.70	32.80	166.497461928934	97.5609756097561	87392849	Completed
60	169	10	184	7	20250506	15.20	89.20	586.8421052631579	33.96860986547085	33497411	Completed
61	150	26	137	9	20250331	48.10	72.80	151.35135135135135	164.2857142857143	82834081	Completed
62	180	35	153	11	20250310	17.70	28.40	160.45197740112994	164.7887323943662	68547925	Paused
63	91	11	166	10	20240311	49.40	60.90	123.27935222672065	148.11165845648605	133788987	Paused
64	103	22	248	7	20240819	10.70	29.20	272.89719626168227	179.1095890410959	27747514	Paused
65	133	15	115	6	20231203	42.40	63.70	150.23584905660377	18.995290423861853	47978853	Paused
66	129	10	89	1	20250512	17.30	42.10	243.35260115606934	259.85748218527317	33497411	Active
67	30	10	90	5	20250503	41.90	25.00	59.66587112171838	456	33497411	Completed
68	90	31	25	8	20240815	58.80	34.20	58.16326530612246	267.8362573099415	84384510	Completed
69	12	8	6	6	20250526	17.70	73.60	415.819209039548	162.22826086956522	99316412	Paused
70	63	34	45	9	20221021	33.20	43.00	129.5180722891566	245.34883720930233	109551712	Completed
71	60	26	162	3	20250130	54.80	43.40	79.1970802919708	143.08755760368663	82834081	Active
72	158	13	116	10	20250217	37.20	65.80	176.88172043010752	72.94832826747721	144270462	Active
73	72	5	148	2	20231209	23.10	34.70	150.21645021645023	336.88760806916423	87392849	Completed
74	30	17	172	8	20250522	77.60	33.70	43.4278350515464	86.94362017804154	62164487	Completed
75	157	26	151	2	20250313	34.60	45.50	131.5028901734104	124.17582417582418	82834081	Active
76	173	20	236	10	20241213	15.90	19.00	119.49685534591195	418.42105263157896	168452858	Active
77	62	20	30	3	20241018	58.50	49.90	85.2991452991453	152.30460921843687	168452858	Completed
78	153	9	148	7	20241003	23.00	60.10	261.30434782608694	194.50915141430949	125611604	Paused
79	166	12	143	3	20250121	30.20	23.30	77.1523178807947	148.068669527897	191894786	Completed
80	159	4	222	6	20240218	43.90	24.00	54.66970387243736	166.25	188238298	Completed
81	144	33	168	8	20240709	57.90	42.10	72.71157167530225	83.3729216152019	11994519	Completed
82	126	11	22	10	20240304	65.70	26.10	39.726027397260275	42.911877394636015	133788987	Active
83	71	15	138	5	20230811	64.70	54.40	84.08037094281298	39.88970588235294	47978853	Completed
84	141	33	29	10	20230911	28.80	52.50	182.29166666666666	73.33333333333333	11994519	Completed
85	139	3	195	12	20240301	48.20	89.20	185.0622406639004	32.95964125560538	263927189	Active
86	168	16	77	1	20250430	28.40	78.70	277.11267605633805	130.3684879288437	199150873	Active
87	113	8	199	4	20250203	66.70	56.20	84.25787106446776	213.16725978647685	99316412	Completed
88	157	28	43	10	20250412	64.90	74.70	115.10015408320493	23.962516733601067	208926759	Active
89	146	23	137	5	20250923	47.70	34.50	72.32704402515724	346.6666666666667	214561504	Paused
90	75	19	147	5	20250502	79.00	63.70	80.63291139240506	147.723704866562	299592333	Active
91	35	27	236	1	20250430	70.70	18.40	26.02545968882602	432.0652173913044	185804259	Active
92	64	10	183	6	20250427	63.30	63.50	100.31595576619274	152.75590551181102	33497411	Completed
93	37	18	161	7	20250614	41.60	60.00	144.23076923076923	179.33333333333334	80551177	Active
94	104	33	192	5	20240529	41.80	48.00	114.83253588516747	156.04166666666669	11994519	Paused
95	1	6	188	8	20250719	56.50	37.40	66.19469026548673	317.9144385026738	53118958	Active
96	137	26	56	7	20250206	44.60	34.50	77.3542600896861	187.82608695652175	82834081	Completed
97	87	9	145	8	20250104	34.10	64.00	187.683284457478	119.53125	125611604	Active
98	12	7	161	8	20250209	18.70	78.30	418.716577540107	137.42017879948915	87142713	Completed
99	117	1	246	7	20250211	79.70	82.60	103.63864491844416	27.602905569007266	69934576	Paused
100	78	11	224	5	20240405	55.80	28.50	51.075268817204304	345.96491228070175	133788987	Completed
101	171	11	14	7	20250103	31.40	65.40	208.2802547770701	28.74617737003058	133788987	Active
102	110	6	181	2	20240828	24.90	14.40	57.83132530120482	447.91666666666663	53118958	Paused
103	58	34	175	8	20220913	10.60	36.20	341.5094339622642	88.67403314917127	109551712	Active
104	109	9	123	2	20240814	36.80	67.90	184.51086956521743	85.27245949926362	125611604	Active
105	27	21	95	5	20230315	36.80	74.70	202.98913043478262	31.325301204819276	131125964	Active
106	165	10	18	9	20250518	10.60	61.30	578.3018867924528	31.973898858075046	33497411	Completed
107	90	14	161	12	20250120	74.40	58.50	78.62903225806451	183.93162393162393	202714730	Completed
108	56	6	230	2	20241107	62.70	56.30	89.792663476874	200.35523978685615	53118958	Completed
109	90	28	81	3	20250426	29.40	14.90	50.68027210884354	512.7516778523491	208926759	Paused
110	154	19	200	12	20241228	69.40	62.00	89.3371757925072	185.6451612903226	299592333	Completed
111	53	34	156	9	20221029	62.30	32.20	51.68539325842698	230.7453416149068	109551712	Active
112	62	32	99	2	20241110	45.00	56.70	126	167.3721340388007	48839383	Paused
113	4	24	240	6	20240221	37.10	76.80	207.00808625336927	109.63541666666667	128845609	Completed
114	94	35	175	3	20250924	76.80	71.20	92.70833333333334	45.08426966292134	68547925	Active
115	151	5	4	5	20230628	12.80	13.00	101.5625	339.2307692307692	87392849	Completed
116	130	19	161	12	20250429	63.70	42.70	67.03296703296704	251.99063231850116	299592333	Completed
117	22	35	138	10	20250414	29.40	33.40	113.60544217687075	64.97005988023952	68547925	Paused
118	53	10	138	6	20250507	51.10	70.60	138.16046966731895	30.736543909348445	33497411	Paused
119	175	5	80	12	20231019	61.10	77.40	126.67757774140755	16.666666666666664	87392849	Active
120	63	6	237	7	20241026	41.70	57.90	138.84892086330933	56.13126079447323	53118958	Completed
121	171	12	31	1	20250218	19.60	8.90	45.40816326530612	1040.4494382022472	191894786	Completed
122	89	34	133	12	20221116	21.70	18.40	84.79262672811059	285.8695652173913	109551712	Completed
123	31	2	86	7	20250310	46.70	29.60	63.38329764453961	46.62162162162162	182752899	Paused
124	161	5	128	8	20231126	35.20	49.00	139.20454545454544	48.97959183673469	87392849	Paused
125	43	24	41	5	20240513	17.20	55.10	320.34883720930236	37.93103448275862	128845609	Paused
126	30	15	190	9	20230518	13.10	78.80	601.5267175572519	77.66497461928934	47978853	Active
127	12	31	94	7	20241125	20.50	84.40	411.7073170731707	120.85308056872037	84384510	Active
128	142	27	58	6	20250426	39.10	67.10	171.6112531969309	119.52309985096872	185804259	Completed
129	20	24	31	9	20240501	73.10	22.70	31.053351573187417	407.9295154185022	128845609	Paused
130	12	26	18	8	20250224	64.10	33.50	52.262090483619346	58.50746268656717	82834081	Active
131	142	30	3	6	20230324	30.40	72.30	237.82894736842107	121.43845089903182	353325145	Paused
132	160	16	119	6	20250511	79.80	71.60	89.72431077694235	88.8268156424581	199150873	Paused
133	140	16	39	1	20250419	11.70	52.40	447.86324786324786	19.274809160305345	199150873	Paused
134	178	1	244	6	20241031	63.10	38.90	61.64817749603803	216.45244215938305	69934576	Paused
135	79	7	53	9	20250309	39.40	86.80	220.3045685279188	120.7373271889401	87142713	Active
136	72	6	12	4	20250521	38.90	81.40	209.25449871465298	141.03194103194102	53118958	Completed
137	22	7	130	3	20250429	67.40	14.10	20.91988130563798	360.9929078014184	87142713	Paused
138	16	28	170	3	20250425	30.40	77.80	255.92105263157896	146.40102827763496	208926759	Completed
139	180	21	82	8	20230418	26.40	85.40	323.4848484848485	79.39110070257611	131125964	Active
140	150	7	40	2	20250228	41.50	33.80	81.44578313253011	213.6094674556213	87142713	Active
141	138	23	247	4	20250711	31.60	29.70	93.9873417721519	237.71043771043767	214561504	Active
142	24	11	207	11	20240722	67.80	65.10	96.01769911504424	153.14900153609833	133788987	Active
143	56	21	38	2	20230412	77.80	40.50	52.05655526992288	129.62962962962962	131125964	Active
144	174	20	67	3	20240722	76.60	78.10	101.95822454308093	19.71830985915493	168452858	Paused
145	141	16	25	8	20250131	66.30	19.50	29.411764705882355	469.7435897435897	199150873	Active
146	16	15	34	4	20231208	36.10	59.70	165.37396121883657	51.75879396984924	47978853	Paused
147	22	17	235	2	20250318	79.80	24.20	30.325814536340854	220.6611570247934	62164487	Paused
148	114	9	24	6	20240718	13.00	45.80	352.3076923076923	34.49781659388646	125611604	Active
149	147	28	211	12	20250515	44.70	39.40	88.14317673378075	59.390862944162436	208926759	Completed
150	45	23	55	3	20250411	29.60	80.40	271.6216216216216	120.89552238805969	214561504	Active
151	158	16	166	5	20250512	38.80	53.20	137.11340206185568	169.54887218045113	199150873	Active
152	23	18	99	3	20250706	24.00	80.50	335.4166666666667	117.88819875776397	80551177	Paused
153	64	35	204	1	20250809	64.70	37.40	57.805255023183925	228.07486631016044	68547925	Paused
154	125	23	234	10	20250806	32.50	30.20	92.92307692307692	274.17218543046357	214561504	Active
155	82	15	8	5	20230615	66.60	46.70	70.12012012012012	221.627408993576	47978853	Completed
156	150	15	250	3	20230707	27.30	27.80	101.83150183150182	405.3956834532374	47978853	Paused
157	15	15	148	7	20231114	75.50	89.30	118.27814569536424	130.9070548712206	47978853	Active
158	46	16	152	6	20250406	74.00	10.30	13.91891891891892	408.7378640776699	199150873	Paused
159	91	10	145	4	20250513	47.90	22.40	46.76409185803758	341.51785714285717	33497411	Active
160	24	4	60	10	20240316	11.40	47.20	414.03508771929825	232.6271186440678	188238298	Completed
161	158	13	207	3	20250126	60.20	83.30	138.37209302325581	119.68787515006002	144270462	Completed
162	16	2	38	10	20251017	74.20	71.50	96.3611859838275	73.42657342657343	182752899	Paused
163	94	5	96	12	20230928	51.00	35.60	69.80392156862744	261.23595505617976	87392849	Completed
164	35	11	188	7	20250110	77.20	61.20	79.27461139896373	194.28104575163397	133788987	Active
165	144	23	58	11	20250919	67.00	39.00	58.208955223880594	205.64102564102564	214561504	Paused
166	177	19	33	3	20241222	76.40	85.80	112.30366492146597	15.268065268065268	299592333	Completed
167	146	3	47	10	20240214	74.50	87.30	117.18120805369128	77.20504009163804	263927189	Active
168	164	7	240	8	20250225	33.20	14.40	43.373493975903614	584.7222222222222	87142713	Completed
169	82	11	163	2	20250214	56.90	67.80	119.15641476274166	86.72566371681417	133788987	Completed
170	115	1	68	4	20250307	58.50	36.70	62.73504273504274	98.63760217983652	69934576	Active
171	1	4	99	8	20240520	39.40	21.60	54.82233502538071	439.35185185185185	188238298	Completed
172	127	25	90	9	20250603	17.10	47.30	276.6081871345029	241.01479915433404	28760553	Paused
173	167	15	42	8	20230623	65.90	10.70	16.236722306525035	913.0841121495328	47978853	Active
174	82	17	244	2	20250325	33.90	80.80	238.3480825958702	104.20792079207921	62164487	Active
175	20	6	87	10	20250708	72.50	65.80	90.75862068965517	133.28267477203647	53118958	Completed
176	168	11	156	7	20240508	13.70	35.10	256.2043795620438	211.68091168091166	133788987	Active
177	105	35	68	11	20250619	30.80	15.90	51.62337662337662	227.67295597484278	68547925	Completed
178	147	32	40	1	20250110	10.30	15.20	147.57281553398056	475	48839383	Paused
179	161	31	52	2	20230825	24.50	60.30	246.12244897959184	153.39966832504146	84384510	Active
180	122	8	79	7	20250411	44.20	62.20	140.7239819004525	40.67524115755627	99316412	Active
181	165	35	100	3	20250803	72.00	38.30	53.194444444444436	34.72584856396867	68547925	Completed
182	12	17	113	8	20250418	25.80	30.00	116.27906976744185	357.3333333333333	62164487	Active
183	39	7	22	11	20250323	66.60	41.90	62.912912912912915	26.730310262529834	87142713	Paused
184	59	4	216	7	20240531	46.60	87.20	187.1244635193133	106.30733944954127	188238298	Paused
185	122	16	122	5	20250125	37.60	78.00	207.44680851063828	25	199150873	Active
186	129	34	205	10	20230303	78.80	20.10	25.507614213197975	234.3283582089552	109551712	Completed
187	45	11	249	4	20240526	18.80	42.70	227.12765957446808	30.679156908665103	133788987	Paused
188	112	13	211	11	20241207	68.40	29.10	42.5438596491228	80.41237113402062	144270462	Paused
189	18	6	100	9	20250319	48.60	78.20	160.90534979423867	17.0076726342711	53118958	Paused
190	118	1	202	12	20250915	51.10	72.10	141.09589041095887	40.915395284327325	69934576	Active
191	107	10	38	10	20250519	50.80	87.10	171.45669291338584	60.27554535017222	33497411	Active
192	28	7	202	5	20250416	71.60	80.00	111.731843575419	36.875	87142713	Completed
193	99	32	147	10	20250309	12.60	30.60	242.85714285714286	307.516339869281	48839383	Active
194	159	26	10	7	20250308	58.30	12.00	20.58319039451115	839.1666666666666	82834081	Completed
195	69	24	6	6	20240516	31.20	31.00	99.35897435897436	385.16129032258067	128845609	Completed
196	179	7	249	4	20250224	31.00	69.00	222.58064516129033	18.985507246376812	87142713	Completed
197	69	27	155	11	20250406	23.20	25.30	109.05172413793103	308.300395256917	185804259	Completed
198	125	34	223	6	20230409	13.90	72.90	524.4604316546763	141.70096021947873	109551712	Active
199	80	33	104	3	20230616	22.20	79.80	359.4594594594595	103.25814536340853	11994519	Active
200	15	16	9	8	20250117	74.30	65.80	88.55989232839839	89.05775075987842	199150873	Completed
201	95	30	130	7	20230304	57.70	27.80	48.18024263431542	183.0935251798561	353325145	Completed
202	153	29	46	8	20250424	48.60	36.20	74.48559670781894	125.13812154696132	202561555	Completed
203	177	6	73	1	20250313	13.50	78.00	577.7777777777778	103.0769230769231	53118958	Active
204	57	15	174	4	20231001	55.60	50.10	90.10791366906474	36.12774451097805	47978853	Paused
205	3	31	234	3	20240708	22.10	73.70	333.48416289592757	112.34735413839891	84384510	Active
206	65	20	183	12	20241226	29.30	81.40	277.81569965870307	119.16461916461915	168452858	Completed
207	118	17	56	8	20250423	57.40	75.60	131.7073170731707	85.71428571428572	62164487	Completed
208	150	7	2	9	20250502	77.70	76.80	98.84169884169884	133.984375	87142713	Paused
209	166	19	77	11	20250118	43.70	35.60	81.46453089244851	288.2022471910112	299592333	Completed
210	164	21	221	5	20230415	55.90	86.10	154.02504472271914	10.452961672473869	131125964	Paused
211	77	13	39	9	20250514	26.80	12.70	47.38805970149254	79.52755905511812	144270462	Paused
212	104	21	175	3	20230214	55.90	89.80	160.64400715563508	35.746102449888646	131125964	Completed
213	108	26	100	12	20241223	50.80	89.60	176.3779527559055	14.843750000000002	82834081	Active
214	88	15	176	9	20240115	73.50	63.10	85.85034013605443	62.59904912836767	47978853	Paused
215	77	11	216	11	20241129	22.70	16.00	70.48458149779736	579.375	133788987	Active
216	67	12	243	11	20250101	55.80	26.20	46.95340501792115	100.76335877862596	191894786	Active
217	79	27	202	6	20250512	28.20	32.10	113.82978723404256	91.90031152647974	185804259	Active
218	121	4	222	11	20240501	50.60	58.90	116.40316205533597	67.74193548387098	188238298	Completed
219	50	33	31	11	20240611	47.10	41.90	88.9596602972399	221.00238663484487	11994519	Active
220	36	13	88	7	20250325	72.50	88.90	122.62068965517241	19.572553430821145	144270462	Active
221	81	12	200	2	20250121	33.30	88.90	266.966966966967	129.4713160854893	191894786	Completed
222	163	4	2	8	20240323	24.70	71.40	289.0688259109312	144.1176470588235	188238298	Paused
223	41	32	202	2	20240914	53.00	59.90	113.01886792452831	49.24874791318865	48839383	Completed
224	110	31	99	1	20230831	47.40	67.90	143.24894514767934	139.76435935198822	84384510	Active
225	83	34	49	1	20230303	10.30	68.20	662.1359223300971	28.592375366568913	109551712	Active
226	178	23	80	3	20250113	36.80	56.30	152.98913043478262	22.91296625222025	214561504	Active
227	17	3	77	5	20240303	60.90	56.90	93.43185550082102	180.3163444639719	263927189	Completed
228	112	9	88	8	20240916	62.50	21.50	34.4	80.93023255813952	125611604	Completed
229	5	15	58	12	20230723	24.80	9.80	39.51612903225807	818.3673469387754	47978853	Paused
230	44	8	94	12	20250527	65.40	38.80	59.32721712538225	262.88659793814435	99316412	Paused
231	66	35	160	1	20250219	56.30	61.60	109.41385435168739	152.43506493506493	68547925	Active
232	13	8	107	8	20250319	18.70	28.70	153.475935828877	126.82926829268293	99316412	Paused
233	40	14	178	11	20250523	10.70	42.50	397.196261682243	251.2941176470588	202714730	Active
234	170	34	70	10	20230213	59.10	42.30	71.57360406091371	100.94562647754138	109551712	Active
235	131	8	73	2	20250108	44.80	57.90	129.24107142857144	138.86010362694302	99316412	Completed
236	134	13	92	12	20250212	30.70	11.20	36.48208469055375	573.2142857142858	144270462	Completed
237	54	31	85	4	20230813	10.90	15.30	140.36697247706422	650.3267973856209	84384510	Active
238	147	32	39	2	20250328	15.30	67.30	439.8692810457516	15.0074294205052	48839383	Completed
239	165	15	117	5	20230929	42.50	16.20	38.11764705882353	135.1851851851852	47978853	Active
240	11	19	93	11	20250312	39.80	17.50	43.969849246231156	285.7142857142857	299592333	Active
241	3	9	170	11	20240730	33.00	81.40	246.66666666666669	139.9262899262899	125611604	Paused
242	69	6	96	6	20241129	18.00	40.80	226.66666666666663	227.94117647058826	53118958	Completed
243	70	25	177	8	20250919	39.50	80.70	204.30379746835442	84.38661710037174	28760553	Active
244	29	9	179	12	20240702	78.70	77.20	98.09402795425667	63.47150259067357	125611604	Active
245	107	31	206	10	20240724	40.70	58.10	142.75184275184273	37.177280550774526	84384510	Completed
246	157	2	221	11	20251029	78.10	18.70	23.943661971830988	48.12834224598931	182752899	Completed
247	29	27	113	1	20250403	28.30	33.80	119.434628975265	317.1597633136095	185804259	Paused
248	174	34	197	12	20230205	60.70	26.40	43.49258649093904	243.1818181818182	109551712	Paused
249	87	34	134	12	20230309	53.30	43.50	81.61350844277673	265.7471264367816	109551712	Paused
250	64	31	89	11	20240723	54.90	20.20	36.79417122040073	541.5841584158416	84384510	Paused
251	157	4	3	11	20240308	45.40	46.50	102.42290748898678	188.81720430107526	188238298	Completed
252	43	5	193	8	20230821	26.90	87.60	325.65055762081784	83.78995433789956	87392849	Active
253	130	15	141	11	20231126	38.20	27.30	71.46596858638743	394.87179487179486	47978853	Completed
254	114	29	23	8	20250211	32.10	88.40	275.38940809968847	53.50678733031674	202561555	Paused
255	168	2	27	7	20250521	12.50	53.00	424	167.54716981132074	182752899	Active
256	155	20	228	9	20241205	24.50	63.10	257.55102040816325	104.12044374009508	168452858	Completed
257	94	4	210	4	20240604	41.80	53.90	128.94736842105263	59.36920222634509	188238298	Paused
258	154	31	184	11	20240214	60.10	17.30	28.785357737104825	175.14450867052022	84384510	Paused
259	57	1	88	6	20250920	77.50	31.90	41.16129032258065	54.54545454545454	69934576	Paused
260	96	7	12	3	20250411	19.80	66.80	337.37373737373736	171.8562874251497	87142713	Paused
261	105	7	66	10	20250304	23.10	84.30	364.93506493506493	112.33689205219454	87142713	Completed
262	56	30	212	4	20230428	17.50	42.00	240	32.61904761904762	353325145	Paused
263	173	8	198	8	20250408	56.10	86.40	154.01069518716577	100.69444444444444	99316412	Active
264	128	1	136	12	20241124	48.70	43.50	89.3223819301848	217.93103448275863	69934576	Paused
265	124	33	200	3	20231111	61.10	18.50	30.27823240589198	622.1621621621622	11994519	Completed
266	169	21	130	7	20230526	78.60	83.10	105.72519083969466	61.251504211793026	131125964	Active
267	71	26	247	6	20250227	41.70	18.90	45.323741007194236	373.5449735449735	82834081	Completed
268	155	33	77	12	20240403	59.80	84.70	141.63879598662209	121.13341204250295	11994519	Paused
269	56	13	54	10	20250501	30.30	36.30	119.80198019801979	157.8512396694215	144270462	Paused
270	34	12	129	9	20250216	54.60	66.20	121.24542124542124	33.383685800604226	191894786	Completed
271	144	31	150	10	20241206	56.70	42.20	74.42680776014109	251.89573459715638	84384510	Paused
272	137	19	225	7	20241225	46.60	10.10	21.67381974248927	798.0198019801979	299592333	Active
273	14	4	52	5	20240523	65.00	88.60	136.30769230769232	104.4018058690745	188238298	Paused
274	65	10	215	1	20250526	64.90	24.70	38.05855161787365	217.00404858299595	33497411	Paused
275	9	23	209	8	20250113	53.10	63.40	119.39736346516007	175.86750788643533	214561504	Paused
276	58	25	61	9	20250915	65.80	65.10	98.93617021276594	116.4362519201229	28760553	Paused
277	171	4	238	7	20240406	39.20	72.60	185.20408163265301	81.267217630854	188238298	Paused
278	81	4	4	12	20240320	24.20	79.20	327.2727272727273	55.68181818181818	188238298	Completed
279	58	24	194	10	20240414	61.70	24.10	39.05996758508914	414.9377593360996	128845609	Paused
280	50	19	115	3	20250110	23.10	22.30	96.53679653679653	54.26008968609865	299592333	Paused
281	31	25	11	7	20250509	49.00	18.70	38.16326530612245	229.94652406417114	28760553	Paused
282	66	1	85	8	20251029	75.60	11.30	14.947089947089948	880.5309734513273	69934576	Completed
283	153	4	199	11	20240505	69.00	32.70	47.39130434782609	366.3608562691131	188238298	Paused
284	141	23	19	12	20250503	46.80	86.50	184.82905982905984	94.33526011560693	214561504	Paused
285	18	33	41	7	20240704	16.40	26.10	159.14634146341464	80.07662835249042	11994519	Active
286	170	22	85	6	20241123	25.30	69.70	275.49407114624506	142.75466284074605	27747514	Paused
287	122	1	30	11	20250426	41.20	82.20	199.5145631067961	92.45742092457421	69934576	Paused
288	160	16	246	1	20250328	36.70	73.30	199.72752043596728	31.10504774897681	199150873	Active
289	99	17	139	12	20250421	11.70	50.40	430.7692307692308	215.6746031746032	62164487	Completed
290	132	33	115	8	20230701	30.80	61.40	199.35064935064935	19.706840390879478	11994519	Completed
291	132	6	243	2	20241121	78.00	71.40	91.53846153846155	36.97478991596638	53118958	Paused
292	2	5	54	11	20240126	64.20	78.90	122.89719626168225	72.62357414448668	87392849	Completed
293	27	14	138	12	20250620	64.30	61.00	94.86780715396579	35.57377049180328	202714730	Active
294	176	10	7	8	20250527	33.20	15.20	45.783132530120476	424.99999999999994	33497411	Active
295	46	17	143	2	20250528	67.50	82.70	122.51851851851852	41.71704957678355	62164487	Completed
296	100	29	162	7	20250204	32.10	39.90	124.29906542056074	155.6390977443609	202561555	Active
297	137	1	165	12	20250912	14.40	69.20	480.55555555555554	66.61849710982659	69934576	Active
298	180	5	92	9	20230503	30.30	64.20	211.88118811881188	100	87392849	Paused
299	23	19	196	8	20250329	37.70	62.20	164.9867374005305	40.19292604501607	299592333	Completed
300	41	35	57	3	20250814	65.80	77.70	118.08510638297872	15.701415701415701	68547925	Completed
301	163	10	77	11	20250528	55.40	86.50	156.13718411552347	118.61271676300578	33497411	Active
302	142	10	32	1	20250412	50.10	40.30	80.43912175648701	50.62034739454094	33497411	Paused
303	22	20	54	12	20250120	73.20	36.20	49.45355191256831	158.28729281767954	168452858	Completed
304	166	33	37	3	20231122	25.50	76.40	299.6078431372549	88.48167539267014	11994519	Active
305	30	12	172	10	20241126	69.60	84.50	121.40804597701151	34.67455621301775	191894786	Paused
306	119	5	75	11	20230413	27.50	24.20	88	471.4876033057851	87392849	Paused
307	125	22	92	3	20250604	55.90	16.20	28.980322003577818	396.2962962962963	27747514	Paused
308	18	13	82	8	20250223	33.00	62.10	188.1818181818182	109.17874396135265	144270462	Paused
309	150	10	145	10	20250505	66.50	86.60	130.22556390977442	88.33718244803696	33497411	Active
310	2	21	64	4	20230530	29.40	37.50	127.55102040816327	177.86666666666667	131125964	Paused
311	85	31	119	8	20240211	64.20	47.90	74.61059190031152	132.77661795407099	84384510	Active
312	45	6	216	5	20241107	72.40	24.10	33.28729281767956	384.6473029045643	53118958	Paused
313	161	5	187	2	20230319	69.50	59.80	86.0431654676259	187.79264214046825	87392849	Paused
314	149	26	197	10	20250206	73.40	53.20	72.47956403269754	120.6766917293233	82834081	Paused
315	139	31	168	3	20240215	37.50	81.10	216.26666666666665	43.27990135635019	84384510	Paused
316	75	9	119	9	20241025	16.30	37.80	231.9018404907975	168.25396825396825	125611604	Active
317	170	16	218	10	20250216	63.00	19.50	30.952380952380953	565.6410256410256	199150873	Active
318	46	10	189	12	20250512	75.70	11.30	14.927344782034346	573.4513274336283	33497411	Completed
319	60	5	68	6	20230707	13.00	25.00	192.30769230769232	144.8	87392849	Completed
320	100	31	235	8	20241105	13.30	88.40	664.6616541353383	60.40723981900452	84384510	Completed
321	27	34	163	5	20230412	61.90	55.40	89.49919224555735	106.13718411552347	109551712	Paused
322	45	25	168	7	20250531	51.10	81.70	159.8825831702544	42.96205630354957	28760553	Active
323	133	17	97	4	20250521	38.40	75.00	195.3125	146	62164487	Completed
324	125	31	228	10	20230815	45.10	19.40	43.015521064301545	338.659793814433	84384510	Active
325	59	5	132	11	20230731	24.80	23.30	93.95161290322581	401.28755364806864	87392849	Completed
326	155	8	170	4	20250328	66.80	67.10	100.44910179640718	169.74664679582713	99316412	Completed
327	173	31	123	4	20240609	21.30	76.30	358.21596244131456	75.88466579292268	84384510	Active
328	63	3	33	10	20240320	21.30	59.60	279.8122065727699	21.97986577181208	263927189	Active
329	147	10	15	3	20250428	74.60	50.40	67.5603217158177	139.484126984127	33497411	Completed
330	154	2	225	12	20251029	56.30	31.20	55.41740674955595	258.3333333333333	182752899	Active
331	56	29	156	8	20250301	21.90	76.10	347.48858447488584	97.63469119579501	202561555	Paused
332	37	12	160	11	20250124	28.50	67.40	236.49122807017548	139.3175074183976	191894786	Completed
333	117	5	59	7	20230923	19.30	9.40	48.70466321243523	776.595744680851	87392849	Paused
334	130	27	212	3	20250407	22.40	81.90	365.62500000000006	16.727716727716725	185804259	Paused
335	10	35	129	2	20250314	43.80	18.70	42.69406392694064	118.18181818181819	68547925	Paused
336	139	1	230	11	20250928	40.20	42.50	105.72139303482587	265.4117647058824	69934576	Active
337	179	34	110	4	20230404	43.70	71.00	162.47139588100686	142.25352112676057	109551712	Completed
338	151	7	109	3	20250311	43.40	27.10	62.44239631336406	84.50184501845018	87142713	Active
339	73	35	105	5	20250502	10.40	69.00	663.4615384615385	166.3768115942029	68547925	Active
340	148	34	31	9	20220912	36.30	24.80	68.31955922865015	373.38709677419354	109551712	Completed
341	105	24	28	3	20240330	55.60	28.80	51.798561151079134	88.19444444444444	128845609	Paused
342	109	24	157	5	20240502	37.80	24.70	65.34391534391536	331.17408906882594	128845609	Paused
343	143	31	46	6	20240524	48.80	28.80	59.016393442622956	157.29166666666666	84384510	Completed
344	148	23	199	12	20250613	61.50	78.10	126.99186991869917	153.393085787452	214561504	Paused
345	31	15	115	12	20230807	17.00	49.70	292.3529411764706	24.346076458752513	47978853	Completed
346	141	4	42	7	20240508	10.40	15.50	149.03846153846155	630.3225806451613	188238298	Active
347	121	28	23	2	20250428	25.50	14.60	57.254901960784316	323.972602739726	208926759	Active
348	99	26	158	11	20250426	30.10	87.00	289.03654485049833	115.40229885057471	82834081	Active
349	45	32	113	1	20241021	69.50	84.30	121.29496402877697	127.16488730723607	48839383	Paused
350	74	13	9	10	20250310	46.10	27.00	58.568329718004335	217.03703703703704	144270462	Active
351	173	3	93	4	20240328	10.00	20.90	209	239.23444976076556	263927189	Completed
352	103	23	172	7	20250617	51.00	50.50	99.01960784313725	58.01980198019802	214561504	Paused
353	18	6	141	5	20250903	68.10	83.00	121.87958883994128	129.87951807228916	53118958	Completed
354	89	18	58	10	20250313	41.80	41.10	98.32535885167465	195.13381995133818	80551177	Active
355	67	12	105	9	20241203	49.10	49.30	100.40733197556008	232.86004056795133	191894786	Completed
356	30	33	245	5	20240129	58.60	87.20	148.80546075085323	124.65596330275228	11994519	Paused
357	124	16	194	6	20250502	57.70	81.50	141.2478336221837	122.69938650306749	199150873	Active
358	124	8	67	2	20250319	54.40	89.50	164.52205882352942	17.206703910614525	99316412	Paused
359	180	15	205	6	20231214	76.90	50.40	65.53966189856956	93.45238095238095	47978853	Active
360	180	17	64	5	20250327	37.90	69.40	183.11345646437996	96.10951008645533	62164487	Completed
361	20	12	122	6	20250104	25.30	55.00	217.3913043478261	35.45454545454545	191894786	Active
362	175	13	128	12	20241221	26.40	27.80	105.30303030303031	86.33093525179856	144270462	Completed
363	53	15	52	4	20231115	20.90	16.70	79.9043062200957	553.8922155688623	47978853	Active
364	174	32	158	1	20250413	77.10	77.50	100.51880674448769	129.5483870967742	48839383	Completed
365	159	21	127	10	20230419	44.40	88.70	199.77477477477478	54.904171364148816	131125964	Paused
366	72	26	57	10	20250115	13.80	73.50	532.6086956521739	16.598639455782312	82834081	Completed
367	139	3	129	6	20240224	70.20	71.60	101.99430199430198	30.8659217877095	263927189	Completed
368	31	34	118	6	20230306	10.60	63.30	597.1698113207548	144.23380726698264	109551712	Completed
369	149	7	84	6	20250426	70.30	23.30	33.14366998577525	404.2918454935622	87142713	Completed
370	61	18	121	10	20250528	35.60	48.90	137.35955056179776	114.92842535787321	80551177	Active
371	108	24	94	7	20240311	41.60	54.90	131.97115384615384	185.79234972677597	128845609	Paused
372	176	15	209	2	20231002	66.30	53.50	80.69381598793363	208.41121495327104	47978853	Completed
373	51	10	205	12	20250421	43.10	8.80	20.417633410672856	535.2272727272726	33497411	Completed
374	128	9	229	11	20241027	47.40	33.90	71.51898734177216	84.66076696165192	125611604	Completed
375	77	17	144	10	20250322	37.90	64.60	170.44854881266488	108.51393188854489	62164487	Active
376	56	17	122	11	20250328	41.50	35.40	85.3012048192771	55.08474576271187	62164487	Completed
377	93	17	89	1	20250507	18.50	79.10	427.5675675675675	138.30594184576486	62164487	Paused
378	51	35	45	5	20250726	32.80	49.90	152.13414634146343	211.42284569138278	68547925	Paused
379	115	6	98	10	20250121	42.50	86.40	203.2941176470588	117.47685185185185	53118958	Active
380	164	22	108	11	20250505	50.00	77.60	155.2	60.05154639175258	27747514	Active
381	21	11	88	4	20240727	32.20	31.90	99.06832298136645	54.54545454545454	133788987	Completed
382	155	26	70	8	20250316	62.40	50.70	81.25	84.22090729783037	82834081	Completed
383	106	11	48	1	20240422	60.90	62.30	102.29885057471265	143.6597110754414	133788987	Paused
384	180	6	54	3	20250319	17.20	13.20	76.74418604651163	434.0909090909091	53118958	Completed
385	141	4	7	7	20240424	63.50	14.80	23.30708661417323	436.4864864864864	188238298	Completed
386	159	10	22	11	20250506	31.70	28.30	89.27444794952682	39.57597173144876	33497411	Completed
387	114	9	34	9	20250117	21.90	10.90	49.7716894977169	283.48623853211006	125611604	Completed
388	84	31	120	9	20241202	29.10	44.50	152.9209621993127	219.5505617977528	84384510	Paused
389	139	12	152	10	20250117	54.20	60.10	110.88560885608855	70.04991680532446	191894786	Paused
390	112	34	164	11	20230125	31.70	36.50	115.14195583596215	156.7123287671233	109551712	Paused
391	59	6	114	5	20250303	38.90	20.80	53.47043701799486	571.1538461538462	53118958	Active
392	1	34	209	3	20221208	30.10	51.90	172.4252491694352	214.83622350674375	109551712	Paused
393	126	31	77	1	20240907	40.10	32.00	79.80049875311721	320.625	84384510	Active
394	2	24	49	7	20240416	40.60	28.50	70.19704433497537	68.42105263157895	128845609	Paused
395	166	25	213	7	20250424	28.40	42.60	150	32.629107981220656	28760553	Active
396	133	18	73	11	20250902	66.60	41.90	62.912912912912915	191.88544152744632	80551177	Active
397	47	9	75	2	20241127	41.90	45.10	107.63723150357995	252.99334811529934	125611604	Paused
398	160	32	49	6	20240719	20.70	87.50	422.70531400966183	22.285714285714285	48839383	Active
399	48	7	73	5	20250223	60.10	67.60	112.4792013311148	118.93491124260358	87142713	Active
400	24	10	4	8	20250425	33.90	33.50	98.82005899705015	131.6417910447761	33497411	Completed
401	96	30	179	1	20230426	15.60	69.50	445.5128205128205	70.50359712230215	353325145	Active
402	15	18	199	7	20250109	48.00	22.90	47.708333333333336	523.1441048034935	80551177	Completed
403	98	1	32	12	20250307	36.90	87.90	238.21138211382114	23.20819112627986	69934576	Active
404	9	13	118	12	20250516	16.60	62.60	377.10843373493975	145.84664536741215	144270462	Active
405	122	25	175	5	20251024	32.60	59.60	182.82208588957053	53.85906040268456	28760553	Active
406	141	34	32	5	20230112	54.70	24.30	44.42413162705667	83.9506172839506	109551712	Active
407	171	14	250	2	20250211	54.30	34.60	63.72007366482505	325.7225433526011	202714730	Active
408	71	8	102	4	20241214	77.80	55.60	71.46529562982005	159.1726618705036	99316412	Paused
409	122	10	96	2	20250427	21.00	15.50	73.80952380952381	600	33497411	Paused
410	87	4	16	6	20240509	20.80	52.00	250	103.84615384615384	188238298	Active
411	33	32	60	6	20250421	65.20	70.00	107.36196319018404	156.85714285714286	48839383	Completed
412	50	2	177	7	20250423	60.70	28.60	47.1169686985173	238.11188811188808	182752899	Active
413	125	29	144	5	20250401	58.80	23.60	40.13605442176871	297.0338983050847	202561555	Active
414	140	23	83	12	20250719	29.30	76.20	260.0682593856655	64.56692913385827	214561504	Paused
415	42	5	136	3	20231026	30.70	29.60	96.41693811074919	320.27027027027026	87392849	Completed
416	117	1	199	11	20250717	36.50	23.20	63.56164383561644	516.3793103448276	69934576	Active
417	159	24	199	10	20240306	32.40	13.20	40.74074074074074	907.5757575757576	128845609	Paused
418	100	13	135	11	20250307	63.60	20.60	32.38993710691824	320.38834951456306	144270462	Completed
419	83	27	165	6	20250409	16.70	62.00	371.25748502994014	74.35483870967742	185804259	Active
420	34	12	224	1	20241215	17.50	23.70	135.42857142857142	416.03375527426164	191894786	Active
421	147	25	169	8	20250711	53.70	56.40	105.02793296089385	63.47517730496453	28760553	Active
422	94	15	156	12	20230622	10.90	83.50	766.0550458715596	88.98203592814372	47978853	Paused
423	126	6	120	11	20240928	35.30	69.00	195.4674220963173	141.59420289855072	53118958	Completed
424	95	4	211	10	20240322	47.00	68.20	145.10638297872342	34.3108504398827	188238298	Completed
425	20	14	246	9	20250106	17.10	26.90	157.30994152046782	84.75836431226766	202714730	Completed
426	49	13	135	11	20250102	49.90	85.70	171.7434869739479	77.01283547257876	144270462	Paused
427	143	27	192	2	20250510	57.20	65.60	114.68531468531467	114.1768292682927	185804259	Completed
428	27	11	203	3	20241125	38.10	35.70	93.70078740157481	92.99719887955183	133788987	Active
429	137	29	239	6	20241206	48.50	89.70	184.94845360824743	96.54403567447045	202561555	Completed
430	106	28	212	12	20250506	52.60	54.20	103.04182509505704	25.276752767527675	208926759	Active
431	97	17	93	8	20250512	77.20	8.00	10.362694300518134	625	62164487	Active
432	73	2	133	3	20250325	10.50	88.70	844.7619047619048	59.301014656144304	182752899	Active
433	81	2	198	12	20250312	74.30	49.90	67.16016150740242	174.34869739478958	182752899	Paused
434	147	10	25	1	20250511	34.90	19.30	55.30085959885387	474.61139896373055	33497411	Completed
435	150	16	60	5	20250322	16.40	40.80	248.78048780487805	269.11764705882354	199150873	Active
436	20	21	203	8	20230324	44.20	81.70	184.841628959276	40.63647490820074	131125964	Paused
437	148	7	153	11	20250317	12.60	74.30	589.6825396825398	62.98788694481831	87142713	Completed
438	21	4	236	6	20240401	71.60	43.60	60.89385474860336	182.3394495412844	188238298	Active
439	59	1	163	11	20250514	13.80	51.00	369.5652173913043	115.29411764705883	69934576	Completed
440	139	10	84	9	20250526	25.50	12.10	47.450980392156865	778.5123966942149	33497411	Paused
441	101	29	193	10	20250418	45.30	26.20	57.83664459161148	280.15267175572524	202561555	Completed
442	101	10	34	6	20250417	43.30	69.10	159.5842956120092	44.7178002894356	33497411	Paused
443	103	17	22	7	20250519	40.40	65.20	161.3861386138614	17.177914110429448	62164487	Active
444	124	13	125	7	20250415	50.00	54.00	108	165.55555555555554	144270462	Paused
445	135	16	63	2	20250314	64.40	34.50	53.57142857142857	35.94202898550725	199150873	Paused
446	23	8	172	7	20250330	35.60	23.60	66.29213483146067	124.15254237288134	99316412	Completed
447	153	2	198	5	20250116	79.10	58.50	73.95701643489255	148.71794871794873	182752899	Completed
448	160	10	113	1	20250426	24.00	38.70	161.25000000000003	277.00258397932816	33497411	Paused
449	22	8	190	1	20250212	76.40	84.00	109.94764397905759	72.85714285714286	99316412	Completed
450	4	22	178	2	20241129	41.50	9.90	23.85542168674699	1078.7878787878788	27747514	Active
451	138	14	53	9	20250425	62.50	53.00	84.8	197.73584905660377	202714730	Paused
452	37	2	97	10	20250926	46.90	28.90	61.620469083155655	378.89273356401384	182752899	Active
453	73	13	203	12	20250407	29.00	46.10	158.9655172413793	72.01735357917572	144270462	Active
454	18	25	170	5	20250815	69.60	62.10	89.22413793103449	183.41384863123994	28760553	Active
455	5	19	223	11	20250330	26.20	39.20	149.61832061068705	263.5204081632653	299592333	Paused
456	26	21	125	10	20230302	23.00	49.10	213.47826086956522	182.0773930753564	131125964	Completed
457	144	2	11	4	20250720	31.30	48.20	153.99361022364218	89.2116182572614	182752899	Paused
458	41	2	89	11	20250420	34.90	32.80	93.98280802292263	333.5365853658537	182752899	Paused
459	71	4	161	5	20240406	72.30	74.80	103.45781466113417	143.85026737967914	188238298	Active
460	143	18	58	3	20250527	72.80	61.90	85.02747252747253	129.5638126009693	80551177	Active
461	98	34	246	11	20230214	71.10	64.30	90.43600562587905	35.45878693623639	109551712	Completed
462	62	10	110	5	20250520	33.00	52.50	159.0909090909091	192.38095238095238	33497411	Active
463	168	9	149	9	20241209	66.00	78.70	119.24242424242425	76.49301143583227	125611604	Completed
464	177	34	233	3	20221230	79.70	88.00	110.41405269761606	92.27272727272727	109551712	Active
465	168	11	82	2	20241129	47.30	67.00	141.64904862579283	101.19402985074628	133788987	Active
466	82	10	187	1	20250502	71.60	42.00	58.659217877094974	267.3809523809524	33497411	Completed
467	78	29	191	11	20250711	29.20	71.90	246.23287671232882	116.13351877607788	202561555	Active
468	34	12	7	10	20250206	28.70	54.50	189.89547038327527	118.5321100917431	191894786	Active
469	153	15	60	11	20230530	35.10	64.40	183.4757834757835	170.49689440993788	47978853	Completed
470	35	33	217	10	20240909	59.80	38.70	64.71571906354517	207.49354005167956	11994519	Completed
471	126	31	36	3	20231118	25.80	41.50	160.85271317829458	220.96385542168676	84384510	Active
472	70	27	57	12	20250420	63.00	13.40	21.26984126984127	91.04477611940298	185804259	Completed
473	158	32	177	6	20250301	72.10	43.10	59.77808599167823	158.00464037122967	48839383	Active
474	156	25	185	6	20250607	52.80	68.90	130.49242424242428	19.01306240928882	28760553	Paused
475	138	34	165	12	20230331	12.70	17.00	133.85826771653544	271.1764705882353	109551712	Completed
476	11	16	133	9	20250416	78.90	11.20	14.195183776932826	469.64285714285717	199150873	Completed
477	133	4	49	5	20240413	37.90	33.00	87.0712401055409	59.09090909090909	188238298	Completed
478	119	11	109	5	20241227	74.30	64.60	86.94481830417226	35.44891640866874	133788987	Active
479	119	29	24	12	20250311	17.90	71.90	401.6759776536314	21.974965229485395	202561555	Paused
480	140	9	101	7	20240907	41.60	22.70	54.56730769230769	89.86784140969162	125611604	Paused
481	52	30	24	5	20230424	58.40	82.40	141.0958904109589	19.174757281553397	353325145	Active
482	32	6	30	12	20250415	54.40	15.00	27.573529411764707	506.6666666666667	53118958	Paused
483	99	33	157	3	20240608	48.50	11.60	23.917525773195877	705.1724137931035	11994519	Active
484	86	10	42	3	20250423	63.80	12.20	19.122257053291538	800.8196721311476	33497411	Completed
485	80	29	74	11	20240928	18.20	18.80	103.2967032967033	258.51063829787233	202561555	Active
486	1	17	4	8	20250518	69.90	52.60	75.25035765379113	83.8403041825095	62164487	Active
487	156	32	61	4	20250507	56.20	45.20	80.42704626334519	167.69911504424778	48839383	Completed
488	21	1	63	9	20250322	53.40	53.70	100.56179775280899	23.091247672253257	69934576	Active
489	13	12	38	1	20250211	34.40	19.90	57.848837209302324	263.81909547738695	191894786	Active
490	171	20	85	2	20240727	17.60	89.50	508.52272727272725	111.1731843575419	168452858	Active
491	173	19	157	11	20250523	50.10	54.10	107.98403193612774	151.20147874306838	299592333	Completed
492	149	24	239	1	20240216	63.80	34.50	54.07523510971787	251.0144927536232	128845609	Completed
493	18	28	216	9	20250403	30.50	19.00	62.295081967213115	487.89473684210526	208926759	Paused
494	71	22	135	7	20250321	24.70	25.10	101.61943319838058	262.9482071713147	27747514	Active
495	28	34	23	8	20230315	58.20	84.60	145.36082474226802	55.91016548463357	109551712	Paused
496	74	28	156	6	20250428	46.80	89.60	191.45299145299145	82.92410714285715	208926759	Completed
497	34	32	134	12	20250529	44.80	74.30	165.8482142857143	155.58546433378197	48839383	Paused
498	60	19	50	1	20250121	11.70	59.30	506.83760683760687	127.31871838111299	299592333	Active
499	54	27	106	1	20250507	34.50	74.10	214.78260869565216	142.78002699055332	185804259	Active
500	3	13	177	5	20250104	65.30	33.20	50.842266462480865	205.12048192771078	144270462	Paused
501	141	21	197	1	20230309	58.00	36.00	62.06896551724138	178.33333333333334	131125964	Paused
502	146	2	214	3	20250129	33.10	35.70	107.85498489425983	54.06162464985994	182752899	Paused
503	123	31	205	1	20240707	19.50	20.70	106.15384615384616	227.53623188405797	84384510	Completed
504	138	22	119	7	20251014	62.00	76.50	123.38709677419355	83.13725490196079	27747514	Completed
505	145	21	143	9	20230212	24.60	64.20	260.9756097560975	53.73831775700934	131125964	Completed
506	17	10	72	1	20250503	78.90	59.40	75.2851711026616	134.84848484848484	33497411	Active
507	147	25	48	10	20250328	70.50	69.60	98.72340425531914	128.59195402298852	28760553	Paused
508	81	3	70	7	20240116	44.80	27.50	61.38392857142858	155.27272727272728	263927189	Completed
509	78	14	135	5	20250126	17.90	72.40	404.46927374301686	91.16022099447513	202714730	Active
510	24	29	130	1	20250811	43.80	49.00	111.87214611872147	103.87755102040816	202561555	Active
511	88	31	188	9	20240117	64.30	19.80	30.79315707620529	600.5050505050505	84384510	Active
512	133	9	53	12	20240626	42.20	66.50	157.5829383886256	157.593984962406	125611604	Paused
513	30	1	80	1	20251017	69.40	79.50	114.55331412103746	16.22641509433962	69934576	Completed
514	120	3	27	9	20240412	56.10	33.60	59.893048128342244	264.2857142857143	263927189	Paused
515	80	14	83	4	20250131	30.10	51.60	171.42857142857142	95.34883720930232	202714730	Completed
516	172	8	70	3	20250121	29.20	9.30	31.849315068493155	459.13978494623655	99316412	Paused
517	144	33	27	4	20240510	48.50	30.20	62.2680412371134	294.03973509933775	11994519	Paused
518	73	16	44	2	20250325	52.90	35.80	67.67485822306237	206.70391061452514	199150873	Completed
519	13	9	8	8	20250203	57.30	16.70	29.144851657940663	619.7604790419161	125611604	Active
520	23	28	101	3	20250522	53.10	33.60	63.27683615819209	60.71428571428571	208926759	Active
521	172	35	21	8	20251112	19.20	74.70	389.0625	96.78714859437751	68547925	Paused
522	120	7	117	5	20250505	55.10	70.90	128.67513611615246	30.8885754583921	87142713	Completed
523	60	15	37	10	20230926	73.90	40.20	54.3978349120433	168.15920398009948	47978853	Paused
524	171	22	202	6	20250213	44.10	13.40	30.38548752834467	220.14925373134326	27747514	Active
525	90	31	119	3	20240103	63.80	57.60	90.28213166144201	110.41666666666666	84384510	Active
526	131	7	104	12	20250519	17.50	53.60	306.2857142857143	153.73134328358208	87142713	Active
527	78	35	119	7	20251124	38.90	58.90	151.413881748072	107.97962648556876	68547925	Paused
528	41	31	99	2	20240202	24.60	64.90	263.82113821138216	146.22496147919875	84384510	Completed
529	112	22	140	12	20241024	22.10	62.90	284.6153846153846	131.63751987281398	27747514	Paused
530	147	32	30	10	20250511	42.40	53.50	126.17924528301887	142.05607476635515	48839383	Completed
531	46	20	245	7	20240801	51.90	64.20	123.69942196531792	169.31464174454828	168452858	Paused
532	98	21	127	11	20230223	16.30	75.00	460.12269938650303	64.93333333333334	131125964	Paused
533	163	1	194	3	20251004	20.40	51.60	252.94117647058826	193.7984496124031	69934576	Completed
534	158	29	51	4	20250611	71.40	32.60	45.65826330532212	351.22699386503064	202561555	Paused
535	78	28	184	6	20250406	50.80	58.10	114.37007874015748	52.151462994836486	208926759	Paused
536	104	9	219	5	20240702	35.80	53.00	148.04469273743018	212.45283018867926	125611604	Active
537	1	23	29	5	20241207	26.50	65.60	247.5471698113207	58.68902439024391	214561504	Completed
538	161	21	183	7	20230522	36.70	52.70	143.59673024523158	184.0607210626186	131125964	Paused
539	45	31	36	4	20240522	36.90	83.80	227.10027100271003	109.4272076372315	84384510	Completed
540	40	19	224	11	20250123	19.40	13.90	71.64948453608248	709.3525179856115	299592333	Active
541	37	32	169	7	20240917	15.90	60.70	381.76100628930817	58.97858319604612	48839383	Completed
542	117	28	160	3	20250523	45.70	53.30	116.63019693654266	176.17260787992495	208926759	Completed
543	99	23	58	3	20250627	52.30	55.40	105.92734225621416	144.76534296028882	214561504	Paused
544	61	33	69	7	20240527	12.30	11.10	90.24390243902438	154.0540540540541	11994519	Completed
545	95	8	149	8	20250101	19.90	68.00	341.70854271356785	88.52941176470588	99316412	Completed
546	120	34	21	9	20230214	16.20	46.70	288.2716049382716	154.81798715203425	109551712	Paused
547	170	5	176	11	20231211	65.90	33.60	50.98634294385432	117.55952380952381	87392849	Active
548	88	35	200	1	20250923	41.80	82.30	196.88995215311007	139.85419198055894	68547925	Paused
549	85	27	91	5	20250502	21.70	65.00	299.53917050691246	172.6153846153846	185804259	Paused
550	78	17	16	11	20250515	50.50	55.00	108.91089108910892	98.18181818181819	62164487	Paused
551	75	2	74	8	20241203	18.90	14.30	75.66137566137567	339.86013986013984	182752899	Completed
552	65	9	158	5	20240826	70.10	9.20	13.124108416547788	1091.304347826087	125611604	Active
553	155	12	233	10	20250222	20.60	44.60	216.50485436893203	182.0627802690583	191894786	Active
554	67	16	125	3	20250520	70.30	36.10	51.351351351351354	247.6454293628809	199150873	Active
555	38	10	215	8	20250508	63.90	27.50	43.03599374021909	194.9090909090909	33497411	Completed
556	164	11	54	10	20250227	68.90	12.50	18.142235123367197	458.4	133788987	Completed
557	30	4	43	8	20240408	43.30	47.10	108.77598152424943	38.00424628450106	188238298	Paused
558	60	25	175	12	20250606	43.20	19.90	46.06481481481481	161.3065326633166	28760553	Completed
559	4	19	238	8	20250329	57.50	86.90	151.1304347826087	67.89413118527042	299592333	Paused
560	11	7	235	9	20250429	34.80	77.20	221.83908045977014	69.17098445595855	87142713	Paused
561	167	18	86	5	20250419	66.20	28.90	43.65558912386707	47.75086505190312	80551177	Paused
562	101	30	198	11	20230403	61.40	56.30	91.69381107491857	154.52930728241563	353325145	Active
563	134	22	174	12	20240926	31.90	8.90	27.899686520376175	203.37078651685394	27747514	Active
564	18	1	106	2	20250726	17.30	44.60	257.80346820809245	237.21973094170403	69934576	Active
565	73	17	50	1	20250319	53.40	12.70	23.782771535580526	594.488188976378	62164487	Paused
566	169	14	244	10	20250525	18.50	86.50	467.56756756756755	97.34104046242774	202714730	Active
567	155	9	97	11	20241229	73.00	54.40	74.52054794520548	201.28676470588235	125611604	Active
568	29	12	65	5	20250118	56.20	14.20	25.266903914590745	350.7042253521127	191894786	Completed
569	71	28	178	11	20250506	28.00	72.00	257.14285714285717	148.33333333333334	208926759	Completed
570	16	25	100	6	20250314	28.10	74.60	265.4804270462633	17.828418230563003	28760553	Active
571	113	5	126	4	20240116	37.50	60.90	162.4	130.70607553366173	87392849	Active
572	37	35	197	7	20250517	53.00	16.70	31.50943396226415	384.4311377245509	68547925	Completed
573	67	7	9	2	20250216	50.00	28.50	57	205.6140350877193	87142713	Completed
574	5	32	39	11	20240710	75.30	62.50	83.00132802124834	16.16	48839383	Completed
575	39	22	232	7	20250416	10.30	66.00	640.7766990291261	110.9090909090909	27747514	Completed
576	123	28	104	12	20250403	47.80	8.30	17.364016736401677	992.7710843373493	208926759	Paused
577	124	8	146	9	20250313	33.30	32.80	98.49849849849849	160.3658536585366	99316412	Active
578	162	6	94	9	20250218	15.60	45.70	292.94871794871796	223.19474835886214	53118958	Completed
579	166	13	46	9	20241110	77.70	62.20	80.05148005148006	72.82958199356914	144270462	Completed
580	179	25	230	2	20250807	58.20	47.90	82.30240549828179	235.49060542797494	28760553	Paused
581	113	13	36	1	20241219	11.80	89.70	760.1694915254237	102.22965440356744	144270462	Active
582	126	25	17	9	20250810	31.50	51.80	164.44444444444446	224.90347490347492	28760553	Completed
583	5	3	87	1	20240217	65.10	11.50	17.665130568356375	762.6086956521739	263927189	Active
584	55	34	118	11	20230421	71.20	20.20	28.370786516853933	451.980198019802	109551712	Paused
585	60	5	10	12	20230521	44.20	9.60	21.719457013574658	1048.9583333333335	87392849	Paused
586	12	16	180	11	20250207	11.00	59.90	544.5454545454545	81.13522537562605	199150873	Completed
587	25	30	157	3	20230217	67.20	16.70	24.851190476190474	489.82035928143716	353325145	Completed
588	153	15	17	4	20231221	33.60	76.50	227.67857142857142	152.28758169934642	47978853	Paused
589	174	26	84	2	20250502	19.60	76.60	390.8163265306122	122.97650130548304	82834081	Active
590	12	12	86	2	20241205	29.20	70.10	240.0684931506849	19.686162624821684	191894786	Active
591	179	24	142	3	20240401	27.10	55.70	205.5350553505535	116.69658886894075	128845609	Active
592	26	25	200	3	20250303	71.60	14.60	20.391061452513966	788.3561643835617	28760553	Active
593	46	6	181	11	20250627	72.10	42.10	58.39112343966713	153.20665083135393	53118958	Completed
594	178	9	53	3	20241127	29.00	44.90	154.82758620689654	233.4075723830735	125611604	Active
595	45	3	153	3	20240405	45.00	85.90	190.88888888888889	54.481955762514545	263927189	Paused
596	78	23	108	1	20250903	26.50	17.60	66.41509433962266	264.77272727272725	214561504	Paused
597	25	24	221	9	20240409	25.30	71.20	281.42292490118575	12.640449438202246	128845609	Paused
598	54	18	14	4	20250130	65.80	64.20	97.56838905775076	29.283489096573206	80551177	Completed
599	128	12	41	11	20241125	13.80	37.90	274.63768115942025	55.145118733509236	191894786	Active
600	112	17	86	10	20250513	13.00	68.70	528.4615384615385	20.087336244541483	62164487	Paused
601	46	11	202	1	20241023	46.00	13.80	30	213.76811594202897	133788987	Active
602	114	21	108	4	20230502	26.10	17.00	65.13409961685824	274.11764705882354	131125964	Active
603	26	16	189	7	20250225	36.30	26.10	71.900826446281	248.2758620689655	199150873	Completed
604	150	32	14	7	20240922	25.10	58.00	231.07569721115536	32.41379310344828	48839383	Active
605	100	24	35	8	20240507	23.60	37.40	158.47457627118644	108.02139037433156	128845609	Completed
606	52	22	33	1	20250615	49.80	31.00	62.24899598393575	42.25806451612903	27747514	Active
607	120	30	108	3	20230429	25.40	32.20	126.77165354330711	144.72049689440993	353325145	Active
608	164	11	148	9	20240614	16.10	78.30	486.335403726708	149.2975734355045	133788987	Completed
609	56	31	215	8	20240101	11.00	43.10	391.8181818181818	124.36194895591647	84384510	Active
610	64	21	112	10	20230405	72.40	56.50	78.03867403314916	21.41592920353982	131125964	Active
611	147	1	107	1	20241120	79.40	68.10	85.7682619647355	53.45080763582967	69934576	Paused
612	9	28	136	7	20250526	66.70	65.10	97.60119940029983	145.6221198156682	208926759	Active
613	116	32	62	2	20250421	62.70	64.80	103.34928229665071	90.27777777777779	48839383	Completed
614	56	9	92	5	20240817	55.30	15.40	27.848101265822788	416.8831168831169	125611604	Completed
615	172	20	42	12	20241109	70.10	69.30	98.85877318116977	140.981240981241	168452858	Active
616	117	30	198	3	20230515	22.90	79.50	347.16157205240177	109.43396226415095	353325145	Paused
617	119	1	221	11	20241206	36.90	64.60	175.06775067750675	13.931888544891642	69934576	Paused
618	9	19	110	5	20250527	48.00	73.10	152.29166666666666	138.1668946648427	299592333	Paused
619	21	22	189	1	20250316	76.20	63.30	83.07086614173228	102.3696682464455	27747514	Active
620	29	25	94	8	20250804	12.90	38.00	294.5736434108527	268.42105263157896	28760553	Paused
621	144	5	144	12	20230622	19.70	35.50	180.2030456852792	197.46478873239434	87392849	Paused
622	30	31	189	10	20241031	77.10	25.20	32.68482490272374	257.14285714285717	84384510	Paused
623	58	21	91	5	20230616	57.60	30.70	53.29861111111111	365.47231270358304	131125964	Active
624	96	23	116	8	20250805	46.90	18.10	38.59275053304905	265.1933701657458	214561504	Paused
625	137	35	231	5	20250914	53.50	73.60	137.5700934579439	46.73913043478261	68547925	Paused
626	17	13	229	8	20241122	15.60	81.60	523.076923076923	35.17156862745098	144270462	Completed
627	20	7	43	5	20250221	58.80	48.70	82.82312925170068	36.755646817248454	87142713	Active
628	134	2	76	7	20251006	47.90	18.80	39.24843423799582	638.2978723404256	182752899	Completed
629	108	29	189	11	20240708	30.40	13.20	43.42105263157895	490.90909090909093	202561555	Active
630	134	22	106	10	20241218	55.90	72.50	129.695885509839	145.93103448275863	27747514	Completed
631	152	34	216	9	20230102	42.10	54.50	129.45368171021377	170.09174311926606	109551712	Completed
632	44	17	59	8	20250502	78.00	71.10	91.15384615384615	102.67229254571028	62164487	Active
633	38	23	73	8	20250215	53.30	21.20	39.77485928705441	379.245283018868	214561504	Paused
634	74	12	250	3	20250218	58.50	62.60	107.00854700854701	180.03194888178913	191894786	Active
635	42	16	30	1	20250327	50.20	44.20	88.04780876494023	171.94570135746605	199150873	Completed
636	48	14	144	12	20241221	56.60	88.20	155.8303886925795	79.47845804988661	202714730	Active
637	96	29	139	3	20250328	31.10	83.50	268.4887459807074	130.17964071856287	202561555	Completed
638	128	10	243	8	20250502	20.90	87.60	419.1387559808613	30.136986301369866	33497411	Paused
639	130	22	166	12	20241124	43.20	31.80	73.6111111111111	283.6477987421384	27747514	Paused
640	171	10	205	10	20250528	73.50	44.30	60.27210884353742	106.32054176072235	33497411	Paused
641	29	31	231	1	20231022	57.50	17.60	30.608695652173918	195.45454545454544	84384510	Active
642	103	15	115	6	20230703	32.80	57.90	176.52439024390245	20.898100172711572	47978853	Active
643	150	34	57	5	20221031	11.60	52.10	449.1379310344828	23.416506717850286	109551712	Completed
644	174	6	250	9	20250317	23.60	34.10	144.4915254237288	330.4985337243402	53118958	Paused
645	131	4	233	11	20240403	37.80	66.70	176.45502645502646	121.73913043478261	188238298	Completed
646	95	25	96	1	20250510	34.10	33.30	97.65395894428151	279.2792792792793	28760553	Completed
647	144	6	56	12	20250412	61.90	42.10	68.0129240710824	153.91923990498813	53118958	Completed
648	74	11	207	12	20240922	61.00	42.00	68.85245901639344	237.38095238095238	133788987	Paused
649	154	6	37	4	20250130	43.20	79.10	183.10185185185182	85.4614412136536	53118958	Completed
650	17	25	23	1	20250611	54.70	30.40	55.575868372943326	155.5921052631579	28760553	Active
651	143	30	182	10	20230308	23.90	76.20	318.82845188284523	29.396325459317584	353325145	Completed
652	142	32	11	5	20250505	31.30	53.90	172.20447284345047	79.77736549165121	48839383	Completed
653	58	2	203	1	20250108	28.40	86.40	304.2253521126761	38.42592592592593	182752899	Paused
654	121	8	168	11	20250223	39.20	48.30	123.21428571428571	72.67080745341616	99316412	Paused
655	166	16	8	2	20250316	44.50	87.60	196.85393258426967	118.15068493150686	199150873	Paused
656	93	31	145	7	20241029	28.10	64.20	228.46975088967972	119.1588785046729	84384510	Paused
657	31	24	132	12	20240418	11.20	29.30	261.6071428571429	319.1126279863481	128845609	Paused
658	15	10	82	8	20250526	19.50	21.40	109.74358974358974	316.8224299065421	33497411	Completed
659	93	27	163	6	20250401	30.30	51.40	169.63696369636963	114.39688715953308	185804259	Active
660	132	13	197	11	20241216	63.50	57.10	89.92125984251969	112.43432574430823	144270462	Active
661	140	21	224	6	20230426	29.00	65.20	224.82758620689654	151.22699386503066	131125964	Completed
662	25	35	149	6	20250409	10.90	50.50	463.30275229357795	119.20792079207921	68547925	Completed
663	125	27	88	3	20250408	25.30	49.30	194.86166007905138	35.29411764705882	185804259	Active
664	144	34	217	9	20230312	48.60	70.00	144.03292181069958	114.71428571428571	109551712	Active
665	107	30	235	2	20230302	67.30	83.70	124.36849925705795	63.79928315412186	353325145	Completed
666	90	20	177	6	20240819	67.20	81.00	120.53571428571428	84.07407407407406	168452858	Paused
667	134	22	45	12	20241128	12.00	74.80	623.3333333333334	141.04278074866312	27747514	Active
668	33	10	177	4	20250501	18.80	18.70	99.46808510638297	364.17112299465236	33497411	Active
669	109	8	20	1	20250414	63.00	11.50	18.253968253968253	893.0434782608696	99316412	Active
670	9	33	152	1	20240909	18.30	28.70	156.83060109289616	146.68989547038328	11994519	Active
671	78	1	194	2	20250102	74.40	24.80	33.33333333333333	403.22580645161287	69934576	Active
672	48	23	8	2	20250204	69.20	85.20	123.12138728323698	121.47887323943661	214561504	Paused
673	90	23	42	9	20251001	26.90	54.80	203.7174721189591	178.28467153284672	214561504	Active
674	149	1	136	4	20251101	23.40	31.10	132.9059829059829	304.8231511254019	69934576	Paused
675	2	7	237	4	20250412	69.60	46.90	67.38505747126437	69.29637526652452	87142713	Paused
676	151	12	113	11	20241203	22.70	37.10	163.43612334801762	288.9487870619946	191894786	Completed
677	109	14	132	4	20250327	17.90	88.70	495.53072625698326	105.41149943630214	202714730	Active
678	120	8	134	3	20250417	63.40	65.80	103.78548895899054	175.6838905775076	99316412	Paused
679	11	6	84	8	20241026	36.90	45.50	123.30623306233063	207.03296703296704	53118958	Paused
680	80	29	58	9	20250122	30.30	78.10	257.7557755775577	102.68886043533932	202561555	Active
681	18	31	241	11	20240216	22.60	89.90	397.787610619469	74.74972191323693	84384510	Completed
682	173	7	102	8	20250414	56.10	15.00	26.737967914438503	590	87142713	Active
683	102	26	178	10	20250109	61.90	81.20	131.17932148626818	131.5270935960591	82834081	Active
684	17	24	250	4	20240319	24.00	77.20	321.6666666666667	145.9844559585492	128845609	Completed
685	32	15	215	7	20240127	29.50	66.50	225.42372881355934	80.6015037593985	47978853	Paused
686	152	18	194	11	20250626	34.90	62.70	179.65616045845272	159.48963317384369	80551177	Completed
687	125	33	72	3	20240825	17.60	28.60	162.5	280.06993006993	11994519	Completed
688	60	9	8	2	20241222	13.70	13.60	99.27007299270073	761.0294117647059	125611604	Paused
689	7	12	98	10	20250214	32.90	32.80	99.69604863221883	309.45121951219517	191894786	Paused
690	25	5	170	9	20231117	65.50	24.60	37.55725190839695	463.0081300813008	87392849	Paused
691	128	32	130	5	20250413	34.10	78.50	230.20527859237535	64.8407643312102	48839383	Paused
692	5	3	111	2	20240223	41.50	77.90	187.710843373494	101.1553273427471	263927189	Completed
693	118	3	9	3	20240316	56.20	71.90	127.93594306049823	81.50208623087622	263927189	Paused
694	43	32	111	3	20241216	60.10	48.00	79.86688851913478	164.16666666666666	48839383	Active
695	146	32	169	9	20250412	50.10	47.00	93.812375249501	76.17021276595743	48839383	Active
696	130	4	101	5	20240420	51.40	39.00	75.87548638132296	52.3076923076923	188238298	Paused
697	91	19	83	1	20241229	51.30	18.50	36.06237816764133	265.94594594594594	299592333	Completed
698	90	2	196	11	20250414	36.60	43.10	117.75956284153006	58.0046403712297	182752899	Completed
699	106	23	15	11	20250327	27.30	61.10	223.8095238095238	115.05728314238952	214561504	Paused
700	22	5	223	5	20230507	33.60	9.60	28.57142857142857	1076.0416666666667	87392849	Completed
701	10	30	169	7	20230612	73.10	29.90	40.902872777017784	119.7324414715719	353325145	Paused
702	121	2	82	7	20250810	37.30	54.90	147.18498659517428	123.49726775956285	182752899	Completed
703	26	14	87	8	20250420	66.80	62.70	93.8622754491018	139.87240829346092	202714730	Active
704	158	20	94	7	20240904	44.80	77.50	172.99107142857144	131.61290322580646	168452858	Active
705	138	14	74	5	20241225	30.80	55.00	178.57142857142856	88.36363636363636	202714730	Active
706	160	6	184	10	20241015	51.40	30.40	59.143968871595334	99.67105263157895	53118958	Paused
707	136	31	110	4	20240205	65.70	61.40	93.45509893455099	164.49511400651465	84384510	Completed
708	130	20	111	11	20241130	31.90	42.00	131.6614420062696	187.61904761904762	168452858	Completed
709	160	33	117	11	20231118	71.70	59.50	82.98465829846583	36.80672268907563	11994519	Paused
710	48	32	55	11	20250306	28.80	60.30	209.375	161.1940298507463	48839383	Paused
711	112	4	134	4	20240403	42.40	27.70	65.33018867924528	417.3285198555957	188238298	Paused
712	176	20	217	7	20241028	32.30	76.10	235.60371517027863	105.51905387647832	168452858	Active
713	163	14	217	7	20250219	67.70	61.00	90.10339734121122	131.63934426229508	202714730	Completed
714	176	16	104	4	20250203	20.50	10.30	50.24390243902439	800	199150873	Completed
715	119	32	144	7	20250211	55.30	11.00	19.891500904159134	637.2727272727271	48839383	Active
716	70	9	8	5	20250105	66.20	62.00	93.65558912386706	166.93548387096774	125611604	Active
717	165	3	247	12	20240307	64.80	12.50	19.290123456790123	564.8	263927189	Active
718	81	20	222	2	20241027	72.80	63.10	86.67582417582418	63.23296354992076	168452858	Active
719	102	9	61	2	20241110	61.40	84.50	137.62214983713355	89.70414201183432	125611604	Paused
720	171	34	65	8	20221004	26.70	18.00	67.41573033707866	276.6666666666667	109551712	Completed
721	85	25	207	12	20250905	26.50	42.70	161.1320754716981	233.4894613583138	28760553	Active
722	28	12	55	5	20250115	38.60	78.80	204.14507772020724	123.3502538071066	191894786	Active
723	126	35	96	12	20250324	32.20	42.80	132.91925465838509	217.28971962616825	68547925	Paused
724	64	18	226	3	20250607	43.30	38.20	88.22170900692842	236.91099476439788	80551177	Completed
725	6	3	216	12	20240329	65.90	12.50	18.96813353566009	741.6	263927189	Paused
726	62	17	142	7	20250424	54.70	65.50	119.74405850091406	99.23664122137404	62164487	Paused
727	32	35	222	4	20250909	37.20	82.60	222.04301075268816	48.30508474576271	68547925	Completed
728	66	20	24	4	20240929	24.70	81.00	327.9352226720648	19.506172839506174	168452858	Completed
729	162	21	226	11	20230523	65.30	30.50	46.70750382848392	296.72131147540983	131125964	Active
730	126	31	189	7	20241128	68.90	66.80	96.9521044992743	97.0059880239521	84384510	Active
731	42	17	130	2	20250430	39.50	67.80	171.64556962025316	75.07374631268436	62164487	Paused
732	84	30	178	1	20230214	54.90	23.10	42.076502732240435	462.3376623376623	353325145	Completed
733	165	9	1	7	20240807	54.00	33.70	62.40740740740742	175.96439169139464	125611604	Active
734	29	11	64	9	20250217	77.90	76.10	97.68934531450576	87.64783180026282	133788987	Active
735	153	27	203	6	20250522	43.50	68.30	157.01149425287358	48.609077598828705	185804259	Completed
736	45	21	205	5	20230330	15.90	38.10	239.62264150943395	123.62204724409449	131125964	Completed
737	97	15	6	1	20240226	55.30	59.40	107.41410488245931	201.010101010101	47978853	Active
738	119	13	68	12	20250606	21.80	40.90	187.61467889908258	88.50855745721273	144270462	Completed
739	154	17	39	2	20250502	21.90	54.50	248.8584474885845	18.53211009174312	62164487	Active
740	135	28	198	8	20250528	18.30	66.50	363.38797814207646	130.82706766917292	208926759	Active
741	69	19	192	8	20250329	19.10	78.20	409.42408376963346	95.78005115089515	299592333	Paused
742	56	19	187	11	20250208	39.30	41.50	105.59796437659034	270.6024096385542	299592333	Active
743	8	19	250	5	20250220	53.20	82.40	154.88721804511277	136.77184466019418	299592333	Completed
744	150	30	22	1	20230601	19.30	34.50	178.75647668393782	32.46376811594203	353325145	Paused
745	102	14	183	7	20250612	39.60	57.00	143.93939393939394	170.17543859649123	202714730	Active
746	25	4	14	6	20240318	43.00	37.10	86.27906976744185	50.67385444743935	188238298	Paused
747	172	3	2	5	20240309	53.40	32.80	61.42322097378276	313.719512195122	263927189	Completed
748	172	24	34	9	20240210	50.60	29.30	57.905138339920946	105.46075085324232	128845609	Paused
749	127	22	225	8	20240901	16.30	66.20	406.13496932515335	121.75226586102717	27747514	Completed
750	37	17	30	6	20250321	78.50	48.90	62.29299363057325	155.4192229038855	62164487	Completed
751	93	28	73	5	20250428	46.20	43.70	94.58874458874459	183.9816933638444	208926759	Active
752	81	32	196	3	20250420	69.70	61.90	88.80918220946916	40.38772213247173	48839383	Completed
753	14	13	39	1	20241228	22.80	46.60	204.38596491228068	21.67381974248927	144270462	Active
754	120	28	30	8	20250331	40.90	89.10	217.84841075794623	85.29741863075196	208926759	Paused
755	125	30	127	2	20230310	18.70	15.70	83.9572192513369	310.1910828025478	353325145	Completed
756	47	11	192	9	20240706	49.40	62.40	126.31578947368422	120.0320512820513	133788987	Active
757	150	1	135	10	20250131	39.10	14.30	36.57289002557545	461.5384615384615	69934576	Completed
758	174	7	228	6	20250210	29.90	88.50	295.9866220735786	74.23728813559322	87142713	Active
759	101	24	152	2	20240317	20.80	14.60	70.1923076923077	288.35616438356163	128845609	Paused
760	169	31	117	11	20241213	28.90	62.00	214.53287197231836	35.32258064516129	84384510	Completed
761	12	29	84	12	20250708	73.50	73.40	99.86394557823131	128.33787465940054	202561555	Active
762	55	4	206	11	20240324	32.60	12.60	38.65030674846626	171.42857142857144	188238298	Active
763	141	25	24	7	20250503	22.50	87.10	387.1111111111111	18.140068886337545	28760553	Completed
764	23	2	219	4	20250113	37.20	41.00	110.21505376344085	274.6341463414634	182752899	Paused
765	168	10	31	5	20250513	66.10	68.30	103.3282904689864	135.5783308931186	33497411	Completed
766	176	9	92	11	20240711	68.20	50.00	73.31378299120234	128.4	125611604	Completed
767	115	25	122	5	20250721	52.00	15.40	29.615384615384617	126.62337662337661	28760553	Completed
768	95	12	112	11	20250113	16.50	50.10	303.6363636363636	24.151696606786427	191894786	Completed
769	174	15	166	11	20230804	75.10	51.20	68.1757656458056	176.171875	47978853	Paused
770	135	6	75	8	20250408	15.50	73.70	475.48387096774195	154.81682496607868	53118958	Completed
771	39	9	176	5	20250118	27.40	43.10	157.2992700729927	91.64733178654292	125611604	Paused
772	13	5	235	1	20231127	17.50	42.80	244.57142857142858	124.76635514018692	87392849	Active
773	119	17	91	5	20250529	15.70	49.30	314.0127388535032	227.58620689655174	62164487	Active
774	170	30	46	3	20230512	13.20	42.10	318.93939393939394	107.60095011876484	353325145	Paused
775	77	21	151	12	20230604	63.00	44.90	71.26984126984127	125.83518930957685	131125964	Completed
776	88	12	55	3	20241130	62.30	57.50	92.29534510433388	169.04347826086956	191894786	Paused
777	28	28	137	1	20250326	37.60	9.10	24.20212765957447	1314.2857142857144	208926759	Paused
778	123	30	178	7	20230605	31.20	74.70	239.42307692307693	142.9718875502008	353325145	Paused
779	93	26	206	5	20250105	18.80	9.10	48.40425531914894	237.36263736263737	82834081	Active
780	5	13	220	1	20241223	43.70	19.90	45.53775743707093	145.22613065326635	144270462	Active
781	112	35	49	2	20250629	63.90	20.10	31.455399061032868	97.01492537313432	68547925	Completed
782	6	8	43	3	20250404	77.50	46.70	60.25806451612903	38.32976445396145	99316412	Completed
783	150	16	52	5	20250415	13.60	8.60	63.23529411764706	1075.5813953488373	199150873	Paused
784	111	27	218	8	20250502	12.60	40.80	323.8095238095238	270.343137254902	185804259	Paused
785	152	32	60	12	20240810	47.00	42.60	90.63829787234043	257.7464788732394	48839383	Completed
786	142	5	69	11	20231009	72.20	17.60	24.37673130193906	97.15909090909092	87392849	Paused
787	166	23	115	12	20250703	11.50	31.60	274.7826086956522	38.291139240506325	214561504	Active
788	121	23	113	4	20250808	25.40	82.50	324.80314960629926	129.93939393939394	214561504	Completed
789	155	30	34	5	20230511	77.20	76.30	98.83419689119171	40.49803407601573	353325145	Paused
790	168	24	204	8	20240517	78.00	21.30	27.307692307692307	400.4694835680751	128845609	Active
791	73	6	171	8	20241102	22.10	20.80	94.11764705882352	556.7307692307692	53118958	Completed
792	26	27	242	8	20250503	26.40	53.70	203.4090909090909	27.746741154562383	185804259	Active
793	92	17	92	11	20250405	22.20	78.50	353.60360360360363	81.78343949044586	62164487	Paused
794	9	5	87	7	20230507	53.20	17.90	33.646616541353374	489.94413407821236	87392849	Active
795	125	17	88	6	20250321	63.90	53.70	84.03755868544602	32.402234636871505	62164487	Active
796	177	33	155	11	20230901	59.40	84.00	141.41414141414143	92.85714285714286	11994519	Completed
797	118	8	250	2	20250517	52.70	78.40	148.76660341555979	143.75	99316412	Active
798	144	3	130	2	20240126	54.10	79.40	146.7652495378928	64.1057934508816	263927189	Completed
799	41	19	182	8	20250430	44.90	79.40	176.83741648106906	28.211586901763223	299592333	Active
800	166	24	86	3	20240220	69.40	44.00	63.400576368876074	31.363636363636363	128845609	Completed
\.


--
-- Data for Name: fact_timesheet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fact_timesheet (sk_timesheet, sk_employee, sk_project, sk_task, sk_cabang, sk_time, hours_worked, work_type, approval_status, billable_hours, non_billable_hours, complete_percentage, schedule_variance, cost_variance, resource_allocated) FROM stdin;
1	2	16	214	8	20250402	4.20	Regular	Pending	4.00	0.00	22	15.10	788.52	1
2	93	16	39	9	20250422	9.70	Regular	Approved	9.00	0.00	96	0.40	18.95	2
3	118	34	204	11	20221212	11.40	Overtime	Pending	0.00	11.00	13	73.90	3837.63	2
4	22	22	81	7	20240918	5.80	Overtime	Pending	5.00	0.00	8	70.60	3818.05	1
5	148	4	162	12	20240529	8.30	Weekend	Approved	8.00	0.00	13	53.80	4552.02	2
6	81	23	3	5	20250406	7.70	Regular	Rejected	0.00	7.00	9	80.10	3772.71	2
7	140	29	179	6	20250526	5.40	Regular	Approved	0.00	5.00	11	43.60	2161.69	1
8	100	9	134	9	20240828	3.40	Weekend	Rejected	0.00	3.00	3	112.20	10025.07	1
9	163	11	6	1	20241120	7.50	Regular	Approved	7.00	0.00	6	111.90	13424.64	2
10	16	24	67	11	20240409	4.90	Regular	Rejected	4.00	0.00	32	10.50	573.62	1
11	77	1	117	6	20241230	9.90	Weekend	Rejected	9.00	0.00	45	12.00	553.80	2
12	90	20	73	11	20250131	10.00	Weekend	Rejected	10.00	0.00	12	70.40	4526.72	2
13	134	16	27	6	20250517	7.40	Overtime	Approved	7.00	0.00	8	81.40	6479.44	2
14	106	6	24	1	20250402	10.80	Overtime	Pending	0.00	10.00	68	5.00	256.90	2
15	174	34	104	10	20230201	6.70	Overtime	Approved	0.00	6.00	8	75.70	5321.71	2
16	113	32	188	7	20241001	2.60	Regular	Approved	0.00	2.00	2	116.30	4362.41	1
17	132	34	31	12	20221104	6.00	Regular	Rejected	0.00	6.00	6	86.60	5587.43	1
18	31	27	29	2	20250512	7.30	Regular	Rejected	7.00	0.00	19	31.20	3695.95	2
19	79	24	78	5	20240407	1.30	Regular	Pending	1.00	0.00	1	104.90	8640.61	1
20	13	20	228	5	20240908	3.00	Weekend	Approved	3.00	0.00	5	62.70	4663.63	1
21	18	3	107	8	20240318	4.40	Overtime	Approved	0.00	4.00	12	32.00	1514.56	1
22	156	9	196	3	20241024	8.00	Overtime	Rejected	0.00	8.00	32	17.00	740.52	2
23	23	27	100	4	20250515	4.70	Regular	Rejected	4.00	0.00	35	8.60	593.49	1
24	166	6	222	3	20240909	7.30	Weekend	Approved	0.00	7.00	18	32.60	1806.69	2
25	165	6	50	10	20240924	11.50	Weekend	Pending	0.00	11.00	15	64.00	4271.36	2
26	31	35	47	1	20250302	9.70	Regular	Rejected	0.00	9.00	14	57.70	6835.14	2
27	22	35	156	6	20250318	7.50	Overtime	Pending	0.00	7.00	10	66.80	3612.54	2
28	107	2	221	9	20250111	5.20	Regular	Pending	0.00	5.00	58	3.80	295.79	1
29	74	10	47	5	20250417	2.70	Overtime	Rejected	0.00	2.00	4	64.70	6868.55	1
30	47	2	183	1	20250106	5.30	Overtime	Pending	0.00	5.00	5	91.70	4507.06	1
31	67	25	242	2	20250305	3.20	Weekend	Rejected	3.00	0.00	21	11.70	1106.82	1
32	30	18	16	6	20250401	7.10	Regular	Approved	0.00	7.00	13	46.90	4375.30	2
33	5	18	142	10	20250525	2.10	Weekend	Rejected	0.00	2.00	3	62.90	4368.40	1
34	146	27	115	2	20250529	3.20	Regular	Approved	3.00	0.00	26	8.90	423.82	1
35	63	35	244	7	20250529	11.00	Overtime	Pending	0.00	11.00	13	73.20	3993.06	2
36	159	19	168	3	20241222	1.70	Overtime	Approved	1.00	0.00	5	33.40	3061.11	1
37	90	14	150	9	20250223	1.50	Weekend	Rejected	0.00	1.00	1	104.80	6738.64	1
38	23	26	179	2	20250118	9.00	Overtime	Approved	0.00	9.00	18	40.00	2760.40	2
39	175	22	163	5	20250212	4.00	Weekend	Approved	4.00	0.00	7	54.80	5182.44	1
40	154	22	5	12	20240902	8.10	Regular	Rejected	8.00	0.00	21	30.70	1468.38	2
41	173	12	106	9	20250217	8.70	Overtime	Rejected	0.00	8.00	8	97.10	8123.39	2
42	138	2	229	11	20250212	8.40	Overtime	Approved	0.00	8.00	29	20.30	1204.80	2
43	100	12	215	12	20241121	2.40	Overtime	Pending	0.00	2.00	4	51.20	4574.72	1
44	6	18	175	12	20250305	3.10	Weekend	Rejected	0.00	3.00	10	29.00	1711.00	1
45	60	32	248	6	20240728	4.10	Weekend	Rejected	0.00	4.00	8	48.20	4263.29	1
46	51	26	29	5	20250421	6.40	Weekend	Pending	0.00	6.00	17	32.10	2765.09	2
47	17	9	191	2	20240719	3.90	Weekend	Pending	0.00	3.00	5	79.60	4916.10	1
48	50	2	249	12	20250413	6.90	Overtime	Rejected	0.00	6.00	53	6.20	264.99	2
49	1	28	165	11	20250401	10.40	Overtime	Approved	0.00	10.00	23	35.70	2342.63	2
50	71	8	175	9	20250410	6.50	Weekend	Pending	0.00	6.00	20	25.60	1447.68	2
51	13	18	236	7	20250419	5.90	Regular	Approved	0.00	5.00	7	73.60	5474.37	1
52	147	2	189	4	20250416	5.70	Regular	Pending	0.00	5.00	9	59.10	3521.77	1
53	80	5	161	11	20230428	1.30	Overtime	Pending	0.00	1.00	1	106.30	9379.91	1
54	65	16	28	8	20250307	11.50	Regular	Approved	11.00	0.00	45	13.90	907.25	2
55	19	29	196	2	20250514	5.90	Regular	Pending	0.00	5.00	24	19.10	1707.16	1
56	97	21	228	12	20230224	9.60	Regular	Approved	0.00	9.00	15	56.10	5074.81	2
57	17	7	174	1	20250419	1.60	Overtime	Approved	1.00	0.00	9	16.50	1019.04	1
58	60	1	117	7	20250226	9.70	Weekend	Rejected	9.00	0.00	44	12.20	1079.09	2
59	117	34	85	10	20221030	2.20	Regular	Rejected	0.00	2.00	2	97.30	8414.50	1
60	147	9	164	9	20240821	4.90	Overtime	Rejected	0.00	4.00	9	52.30	3116.56	1
61	63	9	205	1	20240702	2.40	Weekend	Approved	0.00	2.00	5	44.70	2438.38	1
62	80	35	199	3	20250213	6.20	Weekend	Approved	0.00	6.00	5	113.60	10024.06	2
63	133	10	15	4	20250514	10.00	Weekend	Pending	0.00	10.00	14	60.30	4556.87	2
64	52	13	202	2	20250126	3.10	Overtime	Rejected	0.00	3.00	11	26.40	2249.28	1
65	154	22	219	10	20250411	11.60	Weekend	Approved	11.00	0.00	10	101.00	4830.83	2
66	27	30	225	1	20230607	3.40	Regular	Rejected	0.00	3.00	4	77.20	4123.25	1
67	120	14	62	8	20250307	9.90	Overtime	Pending	0.00	9.00	17	48.60	4266.11	2
68	93	1	19	6	20241107	7.10	Regular	Approved	7.00	0.00	9	74.50	3529.06	2
69	12	2	51	4	20250102	2.90	Overtime	Rejected	0.00	2.00	3	111.60	6307.63	1
70	46	13	6	3	20250106	11.00	Regular	Rejected	0.00	11.00	9	108.40	5803.74	2
71	87	14	79	8	20250212	5.10	Overtime	Rejected	0.00	5.00	20	20.20	1122.11	1
72	17	8	37	3	20250129	3.10	Overtime	Rejected	0.00	3.00	5	64.50	3983.52	1
73	163	16	236	1	20250222	10.40	Overtime	Pending	10.00	0.00	13	69.10	8289.93	2
74	162	18	224	3	20250413	11.70	Overtime	Pending	0.00	11.00	12	86.90	6361.08	2
75	170	5	43	9	20230924	9.30	Weekend	Rejected	0.00	9.00	52	8.60	478.68	2
76	46	21	183	6	20230611	8.90	Overtime	Approved	0.00	8.00	9	88.10	4716.87	2
77	164	3	54	4	20240130	6.00	Regular	Approved	0.00	6.00	10	51.30	3636.14	1
78	97	11	240	6	20240627	7.10	Regular	Pending	7.00	0.00	8	77.10	6974.47	2
79	59	3	120	9	20240324	4.70	Overtime	Approved	0.00	4.00	5	93.00	6470.01	1
80	128	21	70	7	20230214	3.00	Regular	Approved	0.00	3.00	7	39.70	2801.63	1
81	22	19	216	9	20250502	7.00	Regular	Approved	7.00	0.00	8	85.70	4634.66	2
82	31	5	93	1	20231214	3.20	Regular	Rejected	0.00	3.00	6	46.80	5543.93	1
83	175	18	49	12	20250507	12.00	Weekend	Rejected	0.00	12.00	62	7.50	709.27	2
84	3	20	73	6	20250131	12.00	Overtime	Rejected	12.00	0.00	15	68.40	6107.44	2
85	121	33	195	3	20240628	3.50	Weekend	Rejected	0.00	3.00	12	25.90	2238.80	1
86	133	30	185	8	20230429	9.70	Overtime	Pending	0.00	9.00	74	3.40	256.94	2
87	54	29	116	9	20240713	5.10	Weekend	Pending	0.00	5.00	11	42.90	3357.35	1
88	128	23	87	4	20250309	5.70	Overtime	Rejected	0.00	5.00	6	82.00	5786.74	1
89	151	2	146	1	20241126	2.70	Overtime	Rejected	0.00	2.00	5	49.90	3892.70	1
90	98	14	243	7	20241229	6.90	Regular	Approved	0.00	6.00	26	19.50	1886.24	2
91	164	20	24	3	20240810	8.40	Regular	Pending	8.00	0.00	53	7.40	524.51	2
92	7	12	51	2	20250108	4.10	Regular	Approved	0.00	4.00	4	110.40	9868.66	1
93	117	4	95	9	20240218	2.90	Overtime	Approved	2.00	0.00	12	20.50	1772.84	1
94	34	35	108	8	20250501	1.80	Regular	Pending	0.00	1.00	4	44.80	4243.90	1
95	111	31	41	10	20240601	11.30	Weekend	Pending	0.00	11.00	54	9.60	806.78	2
96	71	13	2	3	20250222	1.70	Overtime	Rejected	0.00	1.00	2	101.20	5722.86	1
97	146	32	118	8	20250430	1.40	Regular	Approved	0.00	1.00	2	89.90	4281.04	1
98	89	20	101	10	20250210	9.90	Regular	Approved	9.00	0.00	49	10.50	840.94	2
99	118	25	234	11	20250322	8.70	Regular	Approved	8.00	0.00	11	74.10	3848.01	2
100	62	11	71	11	20241119	4.20	Regular	Rejected	4.00	0.00	6	70.40	5401.79	1
101	127	27	196	9	20250410	11.90	Regular	Pending	11.00	0.00	48	13.10	939.14	2
102	105	29	43	5	20241012	6.60	Overtime	Pending	0.00	6.00	37	11.30	682.29	2
103	98	22	191	7	20241003	5.40	Regular	Approved	5.00	0.00	6	78.10	7554.61	1
104	84	30	125	8	20230218	1.90	Weekend	Pending	0.00	1.00	2	87.50	4655.88	1
105	36	31	211	5	20241015	2.80	Regular	Rejected	0.00	2.00	12	20.60	1430.05	1
106	32	35	190	7	20250216	1.90	Regular	Rejected	0.00	1.00	3	59.30	5460.34	1
107	92	12	56	12	20241124	10.80	Weekend	Pending	0.00	10.00	17	54.00	2707.56	2
108	163	34	165	11	20230313	8.30	Regular	Approved	0.00	8.00	18	37.80	4534.87	2
109	14	1	13	7	20250515	3.20	Regular	Approved	3.00	0.00	18	15.00	802.50	1
110	24	2	108	1	20241025	4.70	Regular	Rejected	0.00	4.00	10	41.90	2422.24	1
111	25	11	186	3	20240311	5.60	Regular	Approved	5.00	0.00	8	60.60	5011.01	1
112	160	14	240	9	20250324	11.30	Regular	Pending	0.00	11.00	13	72.90	4795.36	2
113	83	12	4	7	20250211	4.50	Overtime	Pending	0.00	4.00	10	39.60	2138.80	1
114	169	18	167	10	20250308	1.50	Regular	Approved	0.00	1.00	2	91.70	9019.61	1
115	27	35	203	10	20250216	3.80	Regular	Rejected	0.00	3.00	11	29.40	1570.25	1
116	174	9	86	3	20241126	9.40	Weekend	Approved	0.00	9.00	68	4.40	309.32	2
117	18	22	5	10	20250421	5.90	Weekend	Rejected	5.00	0.00	15	32.90	1557.16	1
118	60	2	158	2	20250109	3.60	Overtime	Pending	0.00	3.00	4	96.80	8561.96	1
119	36	24	128	5	20240301	2.70	Regular	Rejected	2.00	0.00	11	21.30	1478.65	1
120	85	9	72	6	20241128	9.70	Regular	Rejected	0.00	9.00	12	70.40	6789.38	2
121	166	19	193	1	20250218	10.30	Overtime	Approved	10.00	0.00	14	63.10	3497.00	2
122	171	16	206	11	20250302	7.70	Overtime	Rejected	7.00	0.00	36	13.90	990.65	2
123	162	1	17	8	20241117	11.50	Regular	Rejected	11.00	0.00	10	105.00	7686.00	2
124	33	6	45	10	20241210	3.60	Regular	Approved	0.00	3.00	3	101.90	8989.62	1
125	43	13	63	7	20241215	7.70	Overtime	Approved	0.00	7.00	62	4.70	474.56	2
126	70	31	21	6	20240302	5.20	Overtime	Approved	0.00	5.00	7	67.10	3154.37	1
127	40	31	6	7	20240317	10.40	Overtime	Rejected	0.00	10.00	9	109.00	5684.35	2
128	66	25	119	5	20250426	4.10	Weekend	Rejected	4.00	0.00	6	59.50	5391.30	1
129	35	31	51	3	20241123	3.10	Regular	Rejected	0.00	3.00	3	111.40	5754.92	1
130	126	26	237	7	20250325	11.70	Overtime	Approved	0.00	11.00	36	20.80	1389.02	2
131	105	3	236	2	20240223	11.30	Regular	Pending	0.00	11.00	14	68.20	4117.92	2
132	90	33	182	8	20240529	8.70	Weekend	Approved	0.00	8.00	39	13.70	880.91	2
133	63	31	9	6	20240630	8.80	Regular	Rejected	0.00	8.00	15	49.80	2716.59	2
134	67	30	242	11	20230310	3.80	Weekend	Rejected	0.00	3.00	26	11.10	1050.06	1
135	4	8	198	2	20250525	8.80	Overtime	Approved	0.00	8.00	10	78.20	5662.46	2
136	133	13	225	7	20241212	10.10	Overtime	Rejected	0.00	10.00	13	70.50	5327.68	2
137	151	20	188	7	20250123	10.60	Weekend	Pending	10.00	0.00	9	108.30	8448.48	2
138	37	18	192	4	20250315	8.70	Regular	Pending	0.00	8.00	12	66.20	2883.01	2
139	25	5	199	12	20231009	6.80	Weekend	Approved	0.00	6.00	6	113.00	9343.97	2
140	46	24	48	12	20240222	3.20	Regular	Rejected	3.00	0.00	4	86.30	4620.50	1
141	146	14	48	4	20241228	9.20	Regular	Approved	0.00	9.00	10	80.30	3823.89	2
142	113	7	223	11	20250228	1.90	Regular	Approved	1.00	0.00	2	101.40	3803.51	1
143	88	2	150	4	20250221	6.30	Regular	Pending	0.00	6.00	6	100.00	5530.00	2
144	171	3	25	4	20240311	9.70	Overtime	Rejected	0.00	9.00	11	81.90	5837.01	2
145	125	31	194	6	20240616	5.70	Overtime	Rejected	0.00	5.00	6	94.30	10323.02	1
146	62	24	171	7	20240324	7.70	Overtime	Approved	7.00	0.00	7	108.10	8294.51	2
147	117	26	186	3	20241220	7.60	Weekend	Approved	0.00	7.00	11	58.60	5067.73	2
148	95	29	159	11	20250226	6.70	Weekend	Pending	0.00	6.00	6	107.50	6662.85	2
149	5	24	224	1	20240509	4.60	Overtime	Pending	4.00	0.00	5	94.00	6528.30	1
150	157	6	90	7	20250428	11.90	Weekend	Pending	0.00	11.00	10	102.10	6254.65	2
151	156	13	183	3	20250313	10.60	Weekend	Rejected	0.00	10.00	11	86.40	3763.58	2
152	23	20	214	11	20241202	11.90	Overtime	Pending	11.00	0.00	62	7.40	510.67	2
153	124	35	62	4	20250222	2.90	Weekend	Rejected	0.00	2.00	5	55.60	4246.73	1
154	8	11	238	6	20240901	9.40	Regular	Rejected	9.00	0.00	16	49.60	1931.42	2
155	172	8	171	3	20250427	8.00	Overtime	Pending	0.00	8.00	7	107.80	12390.53	2
156	58	5	165	6	20230919	11.00	Weekend	Rejected	0.00	11.00	24	35.10	1597.40	2
157	60	15	67	2	20231012	2.00	Regular	Approved	0.00	2.00	13	13.40	1185.23	1
158	30	24	33	6	20240324	7.30	Regular	Approved	7.00	0.00	56	5.80	541.08	2
159	100	28	82	6	20250411	6.70	Weekend	Rejected	0.00	6.00	10	61.10	5459.28	2
160	3	35	219	8	20250307	2.60	Overtime	Pending	0.00	2.00	2	110.00	9821.90	1
161	38	19	38	12	20241230	7.60	Overtime	Rejected	7.00	0.00	14	44.90	4946.63	2
162	71	31	162	4	20240421	4.20	Overtime	Pending	0.00	4.00	7	57.90	3274.24	1
163	40	14	218	12	20250208	8.70	Regular	Pending	0.00	8.00	8	101.60	5298.44	2
164	77	11	6	9	20240905	4.70	Weekend	Approved	4.00	0.00	4	114.70	5293.41	1
165	101	5	136	12	20230801	4.10	Regular	Rejected	0.00	4.00	4	90.70	6982.99	1
166	25	9	83	10	20250124	9.90	Weekend	Approved	0.00	9.00	20	39.30	3249.72	2
167	148	9	114	12	20241018	4.20	Regular	Pending	0.00	4.00	4	114.60	9696.31	1
168	167	1	93	12	20250327	2.10	Regular	Approved	2.00	0.00	4	47.90	3239.96	1
169	174	11	238	1	20240407	4.90	Overtime	Pending	4.00	0.00	8	54.10	3803.23	1
170	132	22	152	7	20240910	7.90	Overtime	Pending	7.00	0.00	19	34.20	2206.58	2
171	102	32	78	12	20250511	11.50	Weekend	Rejected	0.00	11.00	11	94.70	5691.47	2
172	119	25	71	11	20250521	5.90	Regular	Pending	5.00	0.00	8	68.70	4001.77	1
173	126	33	58	1	20240920	4.00	Weekend	Pending	0.00	4.00	5	76.20	5088.64	1
174	99	31	166	12	20240321	4.30	Regular	Pending	0.00	4.00	5	85.90	6330.83	1
175	104	2	101	9	20250519	6.90	Weekend	Approved	0.00	6.00	34	13.50	711.72	2
176	54	8	47	10	20250127	1.10	Overtime	Approved	0.00	1.00	2	66.30	5188.64	1
177	148	14	168	3	20250104	7.20	Regular	Pending	0.00	7.00	21	27.90	2360.62	2
178	94	35	44	7	20250526	8.20	Regular	Approved	0.00	8.00	11	65.80	5387.70	2
179	169	35	114	3	20250409	6.40	Overtime	Rejected	0.00	6.00	5	112.40	11055.66	2
180	156	35	131	4	20250424	2.10	Regular	Pending	0.00	2.00	2	82.00	3571.92	1
181	77	14	246	3	20250516	7.10	Weekend	Approved	0.00	7.00	31	15.70	724.56	2
182	20	17	67	7	20250405	5.40	Regular	Approved	0.00	5.00	35	10.00	604.80	1
183	138	14	19	11	20250219	11.90	Weekend	Rejected	0.00	11.00	15	69.70	4136.70	2
184	145	33	155	3	20240720	10.00	Overtime	Approved	0.00	10.00	13	68.00	3975.96	2
185	20	18	32	9	20250101	8.50	Overtime	Pending	0.00	8.00	42	11.90	719.71	2
186	93	22	200	5	20240908	10.60	Regular	Approved	10.00	0.00	9	104.50	4950.16	2
187	57	25	244	2	20250314	2.90	Weekend	Approved	2.00	0.00	3	81.30	4860.93	1
188	25	34	90	12	20230204	10.50	Weekend	Approved	0.00	10.00	9	103.50	8558.41	2
189	44	21	243	7	20230326	4.80	Weekend	Rejected	0.00	4.00	18	21.60	1890.86	1
190	123	9	67	1	20241209	6.60	Regular	Rejected	0.00	6.00	43	8.80	702.33	2
191	146	18	14	12	20250516	11.70	Weekend	Pending	0.00	11.00	62	7.10	338.10	2
192	118	12	113	6	20250118	6.50	Overtime	Approved	0.00	6.00	6	100.70	5229.35	2
193	79	6	243	5	20250324	9.50	Regular	Rejected	0.00	9.00	36	16.90	1392.05	2
194	24	11	148	1	20240401	9.20	Weekend	Approved	9.00	0.00	8	107.70	6226.14	2
195	109	33	239	12	20231004	6.30	Weekend	Rejected	0.00	6.00	7	80.30	5769.55	2
196	104	1	158	4	20250509	1.10	Overtime	Rejected	1.00	0.00	1	99.30	5235.10	1
197	63	34	176	10	20220921	7.70	Regular	Rejected	0.00	7.00	19	31.80	1734.69	2
198	45	5	94	3	20231128	4.90	Regular	Approved	0.00	4.00	5	97.10	6129.92	1
199	96	8	87	11	20250213	10.10	Regular	Approved	0.00	10.00	12	77.60	3952.94	2
200	68	14	1	12	20250523	7.30	Regular	Approved	0.00	7.00	12	52.00	3944.20	2
201	119	32	15	6	20240713	7.80	Overtime	Approved	0.00	7.00	11	62.50	3640.62	2
202	90	12	103	6	20241121	2.10	Overtime	Pending	0.00	2.00	3	74.80	4809.64	1
203	106	8	234	8	20241213	2.70	Weekend	Approved	0.00	2.00	3	80.10	4115.54	1
204	96	20	94	7	20240830	6.90	Overtime	Pending	6.00	0.00	7	95.10	4844.39	2
205	42	9	91	12	20241006	1.10	Weekend	Pending	0.00	1.00	1	111.10	6482.68	1
206	11	9	102	7	20241224	4.60	Regular	Pending	0.00	4.00	5	83.90	7928.55	1
207	171	18	31	7	20250408	7.10	Weekend	Rejected	0.00	7.00	8	85.50	6093.58	2
208	129	25	34	2	20250312	9.70	Regular	Pending	9.00	0.00	31	21.20	1816.63	2
209	176	16	14	11	20250402	5.70	Weekend	Rejected	5.00	0.00	30	13.10	1112.06	1
210	75	19	125	2	20250410	3.70	Regular	Rejected	3.00	0.00	4	85.70	5067.44	1
211	72	8	222	5	20250213	8.30	Overtime	Pending	0.00	8.00	21	31.60	2802.60	2
212	180	33	157	3	20231127	11.90	Weekend	Rejected	0.00	11.00	15	69.90	5314.50	2
213	31	9	103	1	20240826	11.90	Regular	Approved	0.00	11.00	15	65.00	7699.90	2
214	24	4	98	7	20240424	4.40	Weekend	Pending	4.00	0.00	4	97.10	5613.35	1
215	123	4	131	7	20240509	1.60	Regular	Approved	1.00	0.00	2	82.50	6584.32	1
216	108	16	82	1	20250220	1.40	Regular	Rejected	1.00	0.00	2	66.40	6098.84	1
217	74	31	72	10	20231002	5.70	Overtime	Approved	0.00	5.00	7	74.40	7898.30	1
218	29	7	172	1	20250505	7.10	Regular	Approved	7.00	0.00	24	22.20	1752.47	2
219	151	34	155	6	20221110	8.20	Regular	Rejected	0.00	8.00	11	69.80	5445.10	2
220	34	8	11	10	20250528	10.00	Regular	Rejected	0.00	10.00	23	33.00	3126.09	2
221	20	35	159	6	20250305	9.00	Regular	Rejected	0.00	9.00	8	105.20	6362.50	2
222	33	13	108	9	20250501	3.80	Weekend	Approved	0.00	3.00	8	42.80	3775.82	1
223	162	8	234	7	20241229	6.30	Weekend	Rejected	0.00	6.00	8	76.50	5599.80	2
224	154	18	179	3	20250216	1.50	Weekend	Pending	0.00	1.00	3	47.50	2271.92	1
225	102	32	176	9	20250329	11.70	Regular	Approved	0.00	11.00	30	27.80	1670.78	2
226	144	25	103	10	20250402	3.30	Regular	Pending	3.00	0.00	4	73.60	6966.24	1
227	132	30	129	12	20230615	3.80	Regular	Approved	0.00	3.00	17	18.30	1180.72	1
228	44	15	12	9	20230915	4.20	Weekend	Pending	0.00	4.00	4	110.60	9681.92	1
229	35	18	224	1	20250517	11.80	Regular	Rejected	0.00	11.00	12	86.80	4484.09	2
230	162	24	84	2	20240505	10.70	Overtime	Rejected	10.00	0.00	11	83.50	6112.20	2
231	84	4	161	1	20240601	4.90	Weekend	Approved	4.00	0.00	5	102.70	5464.67	1
232	138	7	185	12	20250506	5.20	Weekend	Approved	5.00	0.00	40	7.90	468.86	1
233	114	15	84	5	20230829	7.40	Overtime	Pending	0.00	7.00	8	86.80	4456.31	2
234	95	10	231	8	20250417	6.50	Overtime	Pending	0.00	6.00	19	27.90	1729.24	2
235	49	32	242	12	20241010	8.10	Regular	Approved	0.00	8.00	54	6.80	362.17	2
236	101	13	18	3	20241118	5.70	Overtime	Rejected	0.00	5.00	29	13.90	1070.16	1
237	135	9	187	1	20241118	2.10	Overtime	Pending	0.00	2.00	2	110.20	7416.46	1
238	165	3	34	4	20240412	1.90	Regular	Rejected	0.00	1.00	6	29.00	1935.46	1
239	28	35	189	6	20250515	8.80	Regular	Pending	0.00	8.00	14	56.00	3917.20	2
240	42	20	85	8	20240823	3.70	Weekend	Rejected	3.00	0.00	4	95.80	5589.93	1
241	6	3	27	9	20240211	2.10	Overtime	Pending	0.00	2.00	2	86.70	5115.30	1
242	7	15	110	7	20230731	4.90	Overtime	Pending	0.00	4.00	5	96.10	8590.38	1
243	176	8	126	3	20250109	3.50	Overtime	Approved	0.00	3.00	4	76.10	6460.13	1
244	31	24	237	2	20240210	7.60	Regular	Approved	7.00	0.00	23	24.90	2949.65	2
245	174	28	39	11	20250503	7.90	Overtime	Approved	0.00	7.00	78	2.20	154.66	2
246	128	24	239	5	20240506	9.80	Regular	Pending	9.00	0.00	11	76.80	5419.78	2
247	82	10	100	8	20250528	9.80	Overtime	Pending	0.00	9.00	74	3.50	224.00	2
248	72	10	24	6	20250420	3.00	Overtime	Approved	0.00	3.00	19	12.80	1135.23	1
249	124	27	155	11	20250507	2.50	Weekend	Pending	2.00	0.00	3	75.50	5766.69	1
250	138	35	127	9	20250404	10.00	Overtime	Pending	0.00	10.00	21	38.70	2296.85	2
251	135	15	180	2	20230914	5.00	Regular	Pending	0.00	5.00	10	43.60	2934.28	1
252	35	8	16	6	20250314	10.30	Regular	Approved	0.00	10.00	19	43.70	2257.54	2
253	63	14	212	4	20241227	9.20	Regular	Rejected	0.00	9.00	67	4.50	245.47	2
254	7	28	96	1	20250408	8.30	Regular	Approved	0.00	8.00	9	84.70	7571.33	2
255	8	10	94	3	20250417	3.70	Regular	Rejected	0.00	3.00	4	98.30	3827.80	1
256	39	12	121	12	20241207	9.20	Weekend	Approved	0.00	9.00	16	47.00	4551.01	2
257	114	1	74	2	20241209	1.70	Weekend	Pending	1.00	0.00	3	46.90	2407.85	1
258	129	11	3	7	20240921	8.50	Overtime	Rejected	8.00	0.00	10	79.30	6795.22	2
259	147	33	79	12	20240105	5.70	Regular	Approved	0.00	5.00	23	19.60	1167.96	1
260	33	14	103	10	20241227	3.40	Regular	Rejected	0.00	3.00	4	73.50	6484.17	1
261	178	30	123	6	20230515	10.10	Regular	Pending	0.00	10.00	17	47.80	2589.80	2
262	50	18	28	2	20241223	5.00	Overtime	Pending	0.00	5.00	20	20.40	871.90	1
263	139	7	17	4	20250424	1.10	Overtime	Pending	1.00	0.00	1	115.40	5369.56	1
264	62	18	22	10	20250427	1.50	Overtime	Pending	0.00	1.00	13	9.70	744.28	1
265	80	1	92	5	20250209	6.50	Overtime	Approved	6.00	0.00	10	57.70	5091.45	2
266	180	7	85	7	20250512	6.50	Weekend	Pending	6.00	0.00	7	93.00	7070.79	2
267	123	3	75	3	20240124	8.50	Regular	Rejected	0.00	8.00	7	105.60	8427.94	2
268	56	10	197	12	20250422	11.90	Weekend	Rejected	0.00	11.00	19	52.30	4275.00	2
269	115	9	87	5	20240917	7.90	Overtime	Pending	0.00	7.00	9	79.80	6124.65	2
270	62	14	157	10	20250101	11.50	Weekend	Rejected	0.00	11.00	14	70.30	5394.12	2
271	4	10	197	5	20250517	10.50	Regular	Approved	0.00	10.00	16	53.70	3888.42	2
272	44	19	42	2	20250303	7.30	Overtime	Pending	7.00	0.00	7	90.40	7913.62	2
273	67	31	66	8	20240709	11.20	Regular	Rejected	0.00	11.00	12	83.50	7899.10	2
274	74	26	105	10	20250116	5.80	Weekend	Rejected	0.00	5.00	5	109.00	11571.44	1
275	22	27	130	8	20250428	10.70	Weekend	Pending	10.00	0.00	21	40.20	2174.02	2
276	63	1	40	2	20250113	5.10	Weekend	Approved	5.00	0.00	7	67.10	3660.30	1
277	100	30	172	2	20230501	6.10	Weekend	Rejected	0.00	6.00	21	23.20	2072.92	2
278	28	6	47	12	20241022	11.10	Overtime	Approved	0.00	11.00	16	56.30	3938.19	2
279	17	21	88	10	20230612	3.30	Weekend	Approved	0.00	3.00	19	14.10	870.82	1
280	10	35	40	8	20250213	8.00	Overtime	Rejected	0.00	8.00	11	64.20	7053.65	2
281	16	24	203	7	20240405	3.30	Regular	Pending	3.00	0.00	10	29.90	1633.44	1
282	70	17	163	3	20250326	2.60	Overtime	Approved	0.00	2.00	4	56.20	2641.96	1
283	108	34	55	11	20221116	3.00	Regular	Pending	0.00	3.00	3	94.20	8652.27	1
284	88	20	43	4	20241012	11.40	Overtime	Approved	11.00	0.00	64	6.50	359.45	2
285	179	28	91	12	20250514	10.10	Weekend	Rejected	0.00	10.00	9	102.10	5634.90	2
286	83	21	4	3	20230605	11.30	Overtime	Approved	0.00	11.00	26	32.80	1771.53	2
287	68	34	185	1	20230104	11.40	Regular	Rejected	0.00	11.00	87	1.70	128.94	2
288	10	14	191	4	20250330	8.70	Regular	Rejected	0.00	8.00	10	74.80	8218.28	2
289	54	13	249	11	20250327	11.50	Overtime	Approved	0.00	11.00	88	1.60	125.22	2
290	129	8	180	8	20250527	12.00	Overtime	Approved	0.00	12.00	25	36.60	3136.25	2
291	134	22	30	3	20250215	5.70	Regular	Rejected	5.00	0.00	8	70.30	5595.88	1
292	98	19	217	11	20250412	8.00	Weekend	Rejected	8.00	0.00	10	72.30	6993.58	2
293	23	7	23	11	20250209	7.80	Overtime	Pending	7.00	0.00	16	39.50	2725.90	2
294	163	29	129	10	20240714	8.30	Overtime	Pending	0.00	8.00	38	13.80	1655.59	2
295	142	25	30	4	20250428	11.50	Overtime	Approved	11.00	0.00	15	64.50	3158.56	2
296	2	24	201	4	20240409	4.10	Weekend	Approved	4.00	0.00	5	79.60	4156.71	1
297	173	16	2	7	20250113	1.20	Regular	Approved	1.00	0.00	1	101.70	8508.22	1
298	86	11	246	10	20240925	3.70	Overtime	Pending	3.00	0.00	16	19.10	1846.59	1
299	14	28	33	11	20250514	11.80	Regular	Approved	0.00	11.00	90	1.30	69.55	2
300	112	15	26	12	20230720	6.50	Weekend	Rejected	0.00	6.00	11	52.30	2333.63	2
301	142	11	243	6	20240601	2.00	Regular	Approved	2.00	0.00	8	24.40	1194.87	1
302	8	35	236	2	20250409	5.20	Weekend	Rejected	0.00	5.00	7	74.30	2893.24	1
303	163	23	48	4	20250508	10.90	Overtime	Pending	0.00	10.00	12	78.60	9429.64	2
304	97	17	169	1	20250420	1.90	Regular	Rejected	0.00	1.00	5	33.90	3066.59	1
305	29	30	238	10	20230304	2.20	Overtime	Approved	0.00	2.00	4	56.80	4483.79	1
306	20	32	217	6	20241024	5.30	Overtime	Pending	0.00	5.00	7	75.00	4536.00	1
307	161	5	54	11	20231010	5.10	Overtime	Rejected	0.00	5.00	9	52.20	3605.98	1
308	47	20	3	3	20241230	7.20	Weekend	Pending	7.00	0.00	8	80.60	3961.49	2
309	89	31	158	10	20240517	1.10	Weekend	Rejected	0.00	1.00	1	99.30	7952.94	1
310	50	2	138	1	20250303	6.60	Regular	Pending	0.00	6.00	30	15.10	645.37	2
311	56	2	84	3	20241217	1.90	Weekend	Pending	0.00	1.00	2	92.30	7544.60	1
312	52	6	90	12	20250125	6.10	Overtime	Approved	0.00	6.00	5	107.90	9193.08	2
313	50	17	45	4	20250420	11.60	Regular	Rejected	0.00	11.00	11	93.90	4013.29	2
314	43	14	245	12	20250416	5.80	Overtime	Approved	0.00	5.00	5	102.90	10389.81	1
315	82	7	156	7	20250402	3.20	Overtime	Approved	3.00	0.00	4	71.10	4550.40	1
316	116	11	228	1	20241105	3.80	Overtime	Approved	3.00	0.00	6	61.90	5261.50	1
317	102	2	30	3	20250517	4.50	Regular	Approved	0.00	4.00	6	71.50	4297.15	1
318	169	24	96	3	20240514	4.50	Regular	Approved	4.00	0.00	5	88.50	8704.86	1
319	55	30	146	6	20230401	7.20	Overtime	Approved	0.00	7.00	14	45.40	3362.78	2
320	27	18	184	10	20250524	1.80	Weekend	Approved	0.00	1.00	6	28.50	1522.18	1
321	82	21	51	4	20230220	9.80	Overtime	Pending	0.00	9.00	9	104.70	6700.80	2
322	31	8	116	3	20250514	4.60	Overtime	Pending	0.00	4.00	10	43.40	5141.16	1
323	5	1	234	8	20250111	2.40	Overtime	Pending	2.00	0.00	3	80.40	5583.78	1
324	87	2	18	8	20241115	10.10	Overtime	Rejected	0.00	10.00	52	9.50	527.72	2
325	89	26	21	9	20250304	6.40	Regular	Approved	0.00	6.00	9	65.90	5277.93	2
326	127	8	216	6	20250519	2.10	Regular	Pending	0.00	2.00	2	90.60	6495.11	1
327	27	21	221	12	20230530	3.50	Regular	Pending	0.00	3.00	39	5.50	293.75	1
328	138	1	240	12	20241113	3.90	Regular	Pending	3.00	0.00	5	80.30	4765.80	1
329	20	17	85	12	20250503	4.00	Regular	Pending	0.00	4.00	4	95.50	5775.84	1
330	33	21	221	3	20230524	8.00	Weekend	Pending	0.00	8.00	89	1.00	88.22	2
331	148	31	170	8	20240102	4.50	Weekend	Approved	0.00	4.00	4	109.40	9256.33	1
332	76	6	91	9	20241230	8.30	Weekend	Pending	0.00	8.00	7	103.90	11133.92	2
333	127	4	55	1	20240512	3.40	Overtime	Pending	3.00	0.00	3	93.80	6724.52	1
334	54	34	132	6	20230324	11.40	Weekend	Approved	0.00	11.00	12	82.10	6425.15	2
335	34	15	235	6	20231130	11.70	Weekend	Rejected	0.00	11.00	22	41.70	3950.24	2
336	49	5	72	7	20230602	8.50	Weekend	Rejected	0.00	8.00	11	71.60	3813.42	2
337	28	8	62	1	20250408	3.10	Regular	Approved	0.00	3.00	5	55.40	3875.23	1
338	91	17	31	9	20250326	4.90	Regular	Pending	0.00	4.00	5	87.70	6396.84	1
339	131	22	14	8	20241112	5.10	Regular	Rejected	5.00	0.00	27	13.70	569.65	1
340	50	19	49	7	20250205	7.50	Weekend	Rejected	7.00	0.00	38	12.00	512.88	2
341	28	4	166	4	20240302	3.40	Regular	Pending	3.00	0.00	4	86.80	6071.66	1
342	17	35	26	5	20250223	10.70	Weekend	Rejected	0.00	10.00	18	48.10	2970.66	2
343	26	15	188	12	20231001	6.40	Regular	Pending	0.00	6.00	5	112.50	10449.00	2
344	153	19	188	1	20250115	3.00	Weekend	Rejected	3.00	0.00	3	115.90	11153.06	1
345	177	16	44	6	20250122	2.80	Overtime	Approved	2.00	0.00	4	71.20	6472.79	1
346	171	31	110	6	20230822	3.00	Overtime	Pending	0.00	3.00	3	98.00	6984.46	1
347	153	23	249	8	20250420	1.00	Regular	Approved	0.00	1.00	8	12.10	1164.38	1
348	146	19	214	4	20250505	6.50	Regular	Pending	6.00	0.00	34	12.80	609.54	2
349	116	32	189	6	20250415	3.80	Overtime	Approved	0.00	3.00	6	61.00	5185.00	1
350	91	20	182	6	20241124	9.50	Weekend	Approved	9.00	0.00	42	12.90	940.93	2
351	38	27	220	4	20250413	4.90	Regular	Pending	4.00	0.00	17	24.00	2644.08	1
352	93	14	191	2	20250131	11.10	Overtime	Rejected	0.00	11.00	13	72.40	3429.59	2
353	161	35	231	8	20250528	10.60	Regular	Approved	0.00	10.00	31	23.80	1644.10	2
354	85	26	151	7	20250222	4.40	Regular	Rejected	0.00	4.00	8	52.10	5024.52	1
355	157	8	111	8	20250506	11.60	Overtime	Approved	0.00	11.00	15	67.20	4116.67	2
356	128	10	120	11	20250421	6.80	Overtime	Rejected	0.00	6.00	7	90.90	6414.81	2
357	78	32	74	2	20241207	1.20	Regular	Pending	0.00	1.00	2	47.40	3944.63	1
358	14	32	79	1	20250215	4.90	Regular	Pending	0.00	4.00	19	20.40	1091.40	1
359	73	33	171	9	20231023	11.50	Weekend	Approved	0.00	11.00	10	104.30	8768.50	2
360	111	6	75	4	20240913	6.20	Overtime	Pending	0.00	6.00	5	107.90	9067.92	2
361	109	26	248	2	20250218	11.10	Weekend	Approved	0.00	11.00	21	41.20	2960.22	2
362	174	21	206	10	20230315	8.50	Regular	Approved	0.00	8.00	39	13.10	920.93	2
363	78	20	22	5	20241207	11.20	Overtime	Rejected	11.00	0.00	100	0.00	0.00	2
364	25	9	135	8	20241211	4.40	Weekend	Rejected	0.00	4.00	7	61.60	5093.70	1
365	110	30	108	7	20230530	1.30	Weekend	Pending	0.00	1.00	3	45.30	3007.47	1
366	23	9	158	5	20250104	3.70	Weekend	Approved	0.00	3.00	4	96.70	6673.27	1
367	14	26	33	7	20241215	6.10	Weekend	Approved	0.00	6.00	47	7.00	374.50	2
368	15	18	213	11	20241231	4.70	Regular	Approved	0.00	4.00	34	9.20	483.92	1
369	16	8	190	10	20250421	9.10	Regular	Rejected	0.00	9.00	15	52.10	2846.22	2
370	144	32	35	4	20240927	4.30	Overtime	Rejected	0.00	4.00	11	36.10	3416.87	1
371	125	13	30	2	20241031	2.70	Regular	Rejected	0.00	2.00	4	73.30	8024.15	1
372	27	31	7	9	20240326	5.30	Regular	Approved	0.00	5.00	8	59.30	3167.21	1
373	61	35	67	10	20250423	5.80	Weekend	Rejected	0.00	5.00	38	9.60	594.34	1
374	163	2	48	3	20250519	9.20	Regular	Pending	0.00	9.00	10	80.30	9633.59	2
375	122	31	75	5	20240718	2.10	Weekend	Approved	0.00	2.00	2	112.00	4948.16	1
376	101	25	179	2	20250427	5.60	Overtime	Pending	5.00	0.00	11	43.40	3341.37	1
377	31	25	3	10	20250406	1.40	Weekend	Rejected	1.00	0.00	2	86.40	10234.94	1
378	91	9	120	12	20241012	4.00	Regular	Approved	0.00	4.00	4	93.70	6834.48	1
379	90	34	100	9	20220927	2.90	Regular	Approved	0.00	2.00	22	10.40	668.72	1
380	118	9	72	11	20240902	11.20	Regular	Rejected	0.00	11.00	14	68.90	3577.98	2
381	156	12	148	12	20250123	9.50	Weekend	Approved	0.00	9.00	8	107.40	4678.34	2
382	151	23	150	10	20250305	1.70	Regular	Rejected	0.00	1.00	2	104.60	8159.85	1
383	171	7	128	11	20250408	4.60	Regular	Rejected	4.00	0.00	19	19.40	1382.64	1
384	45	25	194	7	20250307	1.70	Overtime	Pending	1.00	0.00	2	98.30	6205.68	1
385	114	24	156	11	20240208	11.20	Overtime	Pending	11.00	0.00	15	63.10	3239.55	2
386	35	13	51	5	20250305	5.80	Overtime	Pending	0.00	5.00	5	108.70	5615.44	1
387	112	34	208	4	20221003	7.40	Weekend	Rejected	0.00	7.00	18	32.80	1463.54	2
388	36	1	93	7	20250325	7.00	Regular	Approved	7.00	0.00	14	43.00	2985.06	2
389	49	14	147	8	20250420	4.90	Weekend	Rejected	0.00	4.00	5	89.20	4750.79	1
390	113	28	161	7	20250404	7.30	Regular	Rejected	0.00	7.00	7	100.30	3762.25	2
391	128	15	14	10	20240217	4.60	Regular	Approved	0.00	4.00	24	14.20	1002.09	1
392	100	23	18	3	20250203	1.80	Weekend	Pending	0.00	1.00	9	17.80	1590.43	1
393	103	4	140	12	20240302	7.40	Overtime	Rejected	7.00	0.00	9	75.40	5542.65	2
394	108	17	52	6	20250323	2.50	Weekend	Rejected	0.00	2.00	3	90.00	8266.50	1
395	61	32	19	10	20250518	8.70	Regular	Approved	0.00	8.00	11	72.90	4513.24	2
396	154	6	228	9	20250430	11.40	Overtime	Rejected	0.00	11.00	17	54.30	2597.17	2
397	128	33	58	11	20240510	5.70	Overtime	Pending	0.00	5.00	7	74.50	5257.46	1
398	7	13	137	10	20250205	8.50	Weekend	Pending	0.00	8.00	7	111.10	9931.23	2
399	100	25	179	3	20250423	8.70	Weekend	Pending	8.00	0.00	18	40.30	3600.80	2
400	158	24	91	4	20240319	5.80	Regular	Pending	5.00	0.00	5	106.40	9092.94	1
401	59	27	192	9	20250331	11.90	Regular	Rejected	11.00	0.00	16	63.00	4382.91	2
402	20	4	33	8	20240311	4.10	Overtime	Approved	4.00	0.00	31	9.00	544.32	1
403	75	9	156	7	20241017	8.20	Weekend	Pending	0.00	8.00	11	66.10	3908.49	2
404	127	23	230	4	20250315	8.80	Overtime	Rejected	0.00	8.00	8	104.00	7455.76	2
405	135	18	82	12	20250421	6.50	Regular	Approved	0.00	6.00	10	61.30	4125.49	2
406	72	6	53	3	20250521	3.50	Weekend	Rejected	0.00	3.00	3	101.30	8984.30	1
407	37	3	61	12	20240301	8.10	Overtime	Pending	0.00	8.00	11	67.70	2948.33	2
408	70	18	151	7	20250218	10.10	Regular	Pending	0.00	10.00	18	46.40	2181.26	2
409	127	2	221	7	20250128	5.90	Regular	Pending	0.00	5.00	66	3.10	222.24	1
410	137	4	170	5	20240221	7.00	Overtime	Pending	7.00	0.00	6	106.90	6270.75	2
411	68	14	194	1	20250310	9.00	Weekend	Approved	0.00	9.00	9	91.00	6902.35	2
412	28	25	244	12	20250524	4.20	Weekend	Approved	4.00	0.00	5	80.00	5596.00	1
413	42	25	120	12	20250329	2.50	Regular	Approved	2.00	0.00	3	95.20	5554.92	1
414	22	16	198	9	20250321	4.70	Overtime	Pending	4.00	0.00	5	82.30	4450.78	1
415	69	17	201	11	20250317	2.40	Weekend	Rejected	0.00	2.00	3	81.30	8814.55	1
416	46	29	119	1	20250208	1.10	Regular	Approved	0.00	1.00	2	62.50	3346.25	1
417	105	4	149	2	20240323	10.90	Weekend	Approved	10.00	0.00	18	49.30	2976.73	2
418	47	17	197	5	20250418	10.60	Regular	Pending	0.00	10.00	17	53.60	2634.44	2
419	159	4	60	2	20240510	1.40	Weekend	Rejected	1.00	0.00	1	108.40	9934.86	1
420	11	15	16	12	20230926	11.70	Regular	Rejected	0.00	11.00	22	42.30	3997.35	2
421	139	3	154	4	20240218	2.20	Weekend	Approved	0.00	2.00	6	33.90	1577.37	1
422	61	14	84	10	20250318	10.10	Weekend	Approved	0.00	10.00	11	84.10	5206.63	2
423	73	10	7	6	20250520	9.70	Overtime	Approved	0.00	9.00	15	54.90	4615.44	2
424	121	19	160	1	20250201	5.10	Overtime	Pending	5.00	0.00	5	88.80	7675.87	1
425	28	14	207	6	20250422	8.90	Weekend	Rejected	0.00	8.00	9	90.80	6351.46	2
426	56	25	213	10	20250303	8.20	Regular	Approved	8.00	0.00	59	5.70	465.92	2
427	20	15	145	9	20240221	9.10	Weekend	Rejected	0.00	9.00	12	67.40	4076.35	2
428	156	31	169	9	20240504	5.90	Overtime	Pending	0.00	5.00	16	29.90	1302.44	1
429	63	22	63	6	20241022	6.00	Weekend	Pending	6.00	0.00	48	6.40	349.12	1
430	105	24	21	6	20240416	6.60	Overtime	Rejected	6.00	0.00	9	65.70	3966.97	2
431	115	27	59	10	20250411	11.20	Regular	Approved	11.00	0.00	15	61.80	4743.15	2
432	156	17	204	5	20250428	4.50	Regular	Approved	0.00	4.00	5	80.80	3519.65	1
433	148	32	162	4	20241010	10.60	Regular	Pending	0.00	10.00	17	51.50	4357.42	2
434	142	31	191	2	20231015	10.60	Overtime	Pending	0.00	10.00	13	72.90	3569.91	2
435	34	33	222	9	20240618	10.90	Overtime	Pending	0.00	10.00	27	29.00	2747.17	2
436	76	8	87	6	20250512	7.70	Regular	Rejected	0.00	7.00	9	80.00	8572.80	2
437	115	27	162	8	20250520	4.20	Overtime	Rejected	4.00	0.00	7	57.90	4443.82	1
438	151	33	22	3	20230525	7.50	Overtime	Rejected	0.00	7.00	67	3.70	288.64	2
439	83	29	46	9	20250425	4.10	Regular	Pending	0.00	4.00	9	41.20	2225.21	1
440	13	34	230	9	20230206	6.60	Overtime	Approved	0.00	6.00	6	106.20	7899.16	2
441	46	10	11	12	20250528	3.30	Weekend	Approved	0.00	3.00	8	39.70	2125.54	1
442	26	23	73	3	20241222	4.20	Overtime	Approved	0.00	4.00	5	76.20	7077.46	1
443	74	17	156	2	20250414	8.30	Regular	Pending	0.00	8.00	11	66.00	7006.56	2
444	8	3	246	9	20240313	9.80	Regular	Approved	0.00	9.00	43	13.00	506.22	2
445	95	14	73	10	20250401	9.10	Weekend	Pending	0.00	9.00	11	71.30	4419.17	2
446	29	8	114	7	20250417	3.90	Regular	Approved	0.00	3.00	3	114.90	9070.21	1
447	91	6	191	4	20241005	4.60	Weekend	Approved	0.00	4.00	6	78.90	5754.97	1
448	177	21	229	1	20230529	2.10	Weekend	Rejected	0.00	2.00	7	26.60	2418.21	1
449	163	1	63	3	20250330	5.10	Regular	Rejected	5.00	0.00	41	7.30	875.78	1
450	39	32	209	3	20250321	4.10	Regular	Rejected	0.00	4.00	4	107.40	10399.54	1
451	1	28	18	8	20250421	8.80	Regular	Approved	0.00	8.00	45	10.80	708.70	2
452	162	16	164	6	20250508	6.80	Regular	Approved	6.00	0.00	12	50.40	3689.28	2
453	172	32	126	11	20250126	7.60	Weekend	Approved	0.00	7.00	10	72.00	8275.68	2
454	29	19	108	8	20250315	3.70	Overtime	Pending	3.00	0.00	8	42.90	3386.53	1
455	170	8	89	12	20250323	8.80	Overtime	Approved	0.00	8.00	8	100.60	5599.40	2
456	8	19	69	9	20250215	10.80	Overtime	Pending	10.00	0.00	63	6.30	245.32	2
457	67	21	106	7	20230601	5.70	Overtime	Pending	0.00	5.00	5	100.10	9469.46	1
458	87	3	79	8	20240226	3.40	Regular	Rejected	0.00	3.00	13	21.90	1216.54	1
459	158	22	34	10	20250329	1.20	Weekend	Pending	1.00	0.00	4	29.70	2538.16	1
460	86	23	197	9	20241208	8.20	Weekend	Pending	0.00	8.00	13	56.00	5414.08	2
461	41	35	102	12	20250224	4.20	Regular	Approved	0.00	4.00	5	84.30	3359.36	1
462	142	16	241	1	20250114	10.30	Weekend	Pending	10.00	0.00	15	56.90	2786.39	2
463	11	11	73	5	20240301	3.50	Weekend	Pending	3.00	0.00	4	76.90	7267.05	1
464	97	26	34	12	20250221	10.50	Regular	Pending	0.00	10.00	34	20.40	1845.38	2
465	6	1	191	9	20250403	11.10	Regular	Rejected	11.00	0.00	13	72.40	4271.60	2
466	50	20	201	6	20241031	6.60	Regular	Approved	6.00	0.00	8	77.10	3295.25	2
467	26	17	249	11	20250528	6.20	Overtime	Approved	0.00	6.00	47	6.90	640.87	2
468	144	18	124	5	20250419	6.60	Overtime	Pending	0.00	6.00	8	78.70	7448.96	2
469	96	35	183	2	20250324	3.50	Regular	Approved	0.00	3.00	4	93.50	4762.89	1
470	95	31	145	2	20240706	4.40	Regular	Rejected	0.00	4.00	6	72.10	4468.76	1
471	144	11	54	8	20241217	3.70	Regular	Approved	3.00	0.00	6	53.60	5073.24	1
472	134	15	16	8	20230923	5.50	Weekend	Approved	0.00	5.00	10	48.50	3860.60	1
473	83	27	224	1	20250429	8.60	Weekend	Approved	8.00	0.00	9	90.00	4860.90	2
474	167	16	83	8	20250508	6.70	Weekend	Rejected	6.00	0.00	14	42.50	2874.70	2
475	109	5	97	3	20230316	2.80	Weekend	Pending	0.00	2.00	3	106.70	7666.39	1
476	30	3	227	7	20240308	2.90	Weekend	Approved	0.00	2.00	4	73.50	6856.82	1
477	103	1	76	2	20250219	12.00	Weekend	Rejected	12.00	0.00	10	108.00	7939.08	2
478	158	24	145	11	20240226	2.60	Weekend	Rejected	2.00	0.00	3	73.90	6315.49	1
479	133	17	121	8	20250411	11.30	Weekend	Rejected	0.00	11.00	20	44.90	3393.09	2
480	43	34	184	8	20220913	4.50	Regular	Pending	0.00	4.00	15	25.80	2605.03	1
481	80	13	52	12	20241124	6.90	Overtime	Pending	0.00	6.00	7	85.60	7553.34	2
482	153	11	18	6	20250108	7.20	Regular	Approved	7.00	0.00	37	12.40	1193.25	2
483	71	19	211	7	20250520	9.00	Overtime	Rejected	9.00	0.00	38	14.40	814.32	2
484	144	35	165	11	20250220	1.90	Regular	Pending	0.00	1.00	4	44.20	4183.53	1
485	46	17	145	2	20250401	9.80	Weekend	Rejected	0.00	9.00	13	66.70	3571.12	2
486	148	18	248	12	20250510	8.40	Overtime	Pending	0.00	8.00	16	43.90	3714.38	2
487	56	6	238	10	20241111	2.60	Overtime	Pending	0.00	2.00	4	56.40	4610.14	1
488	36	33	207	8	20240726	8.30	Overtime	Approved	0.00	8.00	8	91.40	6344.99	2
489	62	26	97	7	20250414	4.90	Weekend	Approved	0.00	4.00	4	104.60	8025.96	1
490	43	18	183	3	20250325	7.20	Overtime	Rejected	0.00	7.00	7	89.80	9067.11	2
491	143	28	167	6	20250417	1.30	Overtime	Approved	0.00	1.00	1	91.90	4888.16	1
492	109	14	158	9	20250130	5.20	Regular	Rejected	0.00	5.00	5	95.20	6840.12	1
493	114	24	135	4	20240205	7.40	Overtime	Pending	7.00	0.00	11	58.60	3008.52	2
494	129	1	156	5	20241108	8.10	Weekend	Approved	8.00	0.00	11	66.20	5672.68	2
495	71	4	249	10	20240601	1.30	Weekend	Approved	1.00	0.00	10	11.80	667.29	1
496	126	12	122	12	20250210	9.30	Regular	Pending	0.00	9.00	48	10.20	681.16	2
497	46	9	22	7	20250116	10.30	Regular	Approved	0.00	10.00	92	0.90	48.19	2
498	81	7	220	9	20250314	11.80	Regular	Rejected	11.00	0.00	41	17.10	805.41	2
499	86	21	230	12	20230323	11.00	Weekend	Rejected	0.00	11.00	10	101.80	9842.02	2
500	171	26	107	11	20241229	1.70	Weekend	Pending	0.00	1.00	5	34.70	2473.07	1
501	45	29	12	5	20250505	3.20	Weekend	Approved	0.00	3.00	3	111.60	7045.31	1
502	80	18	144	6	20250103	4.80	Weekend	Rejected	0.00	4.00	7	65.30	5762.07	1
503	23	8	236	2	20250127	9.00	Regular	Approved	0.00	9.00	11	70.50	4865.20	2
504	44	1	56	11	20250203	6.10	Weekend	Pending	6.00	0.00	9	58.70	5138.60	2
505	34	20	14	7	20250111	4.20	Overtime	Pending	4.00	0.00	22	14.60	1383.06	1
506	58	13	70	4	20241215	11.80	Overtime	Rejected	0.00	11.00	28	30.90	1406.26	2
507	126	23	149	6	20250219	9.50	Weekend	Approved	0.00	9.00	16	50.70	3385.75	2
508	10	25	40	9	20250510	3.30	Weekend	Approved	3.00	0.00	5	68.90	7570.04	1
509	54	22	180	9	20250404	10.10	Overtime	Pending	10.00	0.00	21	38.50	3013.01	2
510	67	14	120	5	20241221	11.10	Weekend	Rejected	0.00	11.00	11	86.60	8192.36	2
511	36	30	151	6	20230507	7.20	Weekend	Rejected	0.00	7.00	13	49.30	3422.41	2
512	180	7	162	6	20250208	2.70	Overtime	Approved	2.00	0.00	4	59.40	4516.18	1
513	48	23	79	3	20250321	7.00	Regular	Approved	0.00	7.00	28	18.30	1466.20	2
514	152	28	188	7	20250525	10.20	Overtime	Rejected	0.00	10.00	9	108.70	7117.68	2
515	124	26	77	1	20250211	9.40	Weekend	Pending	0.00	9.00	9	93.20	7118.62	2
516	148	26	152	1	20250124	6.60	Overtime	Rejected	0.00	6.00	16	35.50	3003.66	2
517	146	9	34	11	20240910	9.70	Regular	Pending	0.00	9.00	31	21.20	1009.54	2
518	89	30	102	3	20230529	1.00	Regular	Pending	0.00	1.00	1	87.50	7007.88	1
519	79	6	48	4	20241210	5.80	Weekend	Pending	0.00	5.00	6	83.70	6894.37	1
520	2	31	41	6	20231002	6.20	Weekend	Approved	0.00	6.00	30	14.70	767.63	2
521	172	25	213	8	20250528	3.70	Regular	Approved	3.00	0.00	27	10.20	1172.39	1
522	103	21	230	5	20230527	7.60	Weekend	Pending	0.00	7.00	7	105.20	7733.25	2
523	57	12	197	4	20250106	5.00	Weekend	Pending	0.00	5.00	8	59.20	3539.57	1
524	20	15	36	8	20230821	1.50	Overtime	Approved	0.00	1.00	2	90.20	5455.30	1
525	168	12	109	3	20241226	4.40	Weekend	Approved	0.00	4.00	19	18.50	1068.19	1
526	46	11	102	11	20241108	10.20	Overtime	Pending	10.00	0.00	12	78.30	4192.18	2
527	168	26	206	1	20250124	4.50	Weekend	Rejected	0.00	4.00	21	17.10	987.35	1
528	3	32	168	11	20250131	5.60	Regular	Approved	0.00	5.00	16	29.50	2634.06	1
529	155	29	129	6	20250225	8.80	Weekend	Approved	0.00	8.00	40	13.30	659.15	2
530	109	35	195	7	20250517	8.40	Regular	Pending	0.00	8.00	29	21.00	1508.85	2
531	51	33	209	10	20240825	5.80	Overtime	Approved	0.00	5.00	5	105.70	9105.00	1
532	118	24	13	10	20240502	5.10	Overtime	Approved	5.00	0.00	28	13.10	680.28	1
533	139	18	46	5	20250305	5.60	Overtime	Approved	0.00	5.00	12	39.70	1847.24	1
534	153	8	92	12	20241221	6.80	Overtime	Pending	0.00	6.00	11	57.40	5523.60	2
535	33	10	163	8	20250509	10.80	Overtime	Approved	0.00	10.00	18	48.00	4234.56	2
536	135	30	11	2	20230425	5.10	Regular	Rejected	0.00	5.00	12	37.90	2550.67	1
537	98	33	186	2	20240427	11.20	Weekend	Approved	0.00	11.00	17	55.00	5320.15	2
538	48	17	185	11	20250326	10.20	Overtime	Pending	0.00	10.00	78	2.90	232.35	2
539	78	33	139	4	20230707	5.10	Overtime	Pending	0.00	5.00	5	103.60	8621.59	1
540	71	12	71	9	20250213	1.50	Overtime	Pending	0.00	1.00	2	73.10	4133.80	1
541	2	27	54	1	20250518	8.20	Overtime	Approved	8.00	0.00	14	49.10	2564.00	2
542	25	15	58	1	20231030	3.40	Weekend	Approved	0.00	3.00	4	76.80	6350.59	1
543	151	27	163	10	20250507	7.00	Overtime	Rejected	7.00	0.00	12	51.80	4040.92	2
544	82	23	211	8	20241230	6.10	Weekend	Approved	0.00	6.00	26	17.30	1107.20	2
545	173	25	66	7	20250303	8.30	Weekend	Pending	8.00	0.00	9	86.40	7228.22	2
546	22	14	192	9	20250317	4.30	Overtime	Approved	0.00	4.00	6	70.60	3818.05	1
547	40	11	160	6	20241203	5.70	Regular	Approved	5.00	0.00	6	88.20	4599.63	1
548	61	25	236	9	20250315	5.20	Regular	Pending	5.00	0.00	7	74.30	4599.91	1
549	29	19	46	3	20250403	7.10	Overtime	Pending	7.00	0.00	16	38.20	3015.51	2
550	82	24	162	2	20240430	10.70	Weekend	Rejected	10.00	0.00	17	51.40	3289.60	2
551	58	26	127	8	20250225	10.10	Overtime	Pending	0.00	10.00	21	38.60	1756.69	2
552	103	19	1	9	20250317	9.40	Weekend	Pending	9.00	0.00	16	49.90	3668.15	2
553	99	27	250	7	20250517	3.10	Regular	Rejected	3.00	0.00	3	109.60	8077.52	1
554	154	27	243	1	20250506	7.70	Regular	Rejected	7.00	0.00	29	18.70	894.42	2
555	95	2	191	10	20250512	8.20	Weekend	Rejected	0.00	8.00	10	75.30	4667.09	2
556	118	24	186	4	20240227	6.20	Weekend	Pending	6.00	0.00	9	60.00	3115.80	2
557	17	2	53	10	20250217	6.10	Weekend	Rejected	0.00	6.00	6	98.70	6095.71	2
558	46	30	129	11	20230301	9.80	Overtime	Pending	0.00	9.00	44	12.30	658.54	2
559	2	3	175	11	20240226	10.50	Overtime	Approved	0.00	10.00	33	21.60	1127.95	2
560	67	35	31	12	20250505	7.70	Weekend	Rejected	0.00	7.00	8	84.90	8031.54	2
561	16	19	208	7	20250101	5.00	Weekend	Rejected	5.00	0.00	12	35.20	1922.98	1
562	110	8	27	3	20250217	9.30	Weekend	Pending	0.00	9.00	10	79.50	5278.00	2
563	106	22	37	4	20250228	3.30	Regular	Approved	3.00	0.00	5	64.30	3303.73	1
564	118	32	193	4	20241120	4.80	Weekend	Approved	0.00	4.00	7	68.60	3562.40	1
565	180	17	146	5	20250320	9.40	Regular	Rejected	0.00	9.00	18	43.20	3284.50	2
566	95	24	183	5	20240315	11.40	Regular	Rejected	11.00	0.00	12	85.60	5305.49	2
567	113	19	40	12	20250123	2.60	Overtime	Approved	2.00	0.00	4	69.60	2610.70	1
568	8	14	150	5	20250119	7.40	Overtime	Approved	0.00	7.00	7	98.90	3851.17	2
569	123	11	249	6	20250112	2.70	Weekend	Approved	2.00	0.00	21	10.40	830.02	1
570	125	11	223	9	20241021	2.90	Overtime	Pending	2.00	0.00	3	100.40	10990.79	1
571	88	15	80	4	20230908	2.70	Weekend	Rejected	0.00	2.00	21	10.20	564.06	1
572	92	32	118	10	20240716	10.20	Weekend	Pending	0.00	10.00	11	81.10	4066.35	2
573	171	3	103	11	20240117	11.50	Weekend	Pending	0.00	11.00	15	65.40	4661.06	2
574	15	29	146	9	20241101	3.70	Weekend	Pending	0.00	3.00	7	48.90	2572.14	1
575	59	30	46	1	20230410	7.10	Regular	Rejected	0.00	7.00	16	38.20	2657.57	2
576	34	34	78	1	20221103	3.50	Weekend	Rejected	0.00	3.00	3	102.70	9728.77	1
577	138	4	82	11	20240226	3.20	Regular	Approved	3.00	0.00	5	64.60	3834.01	1
578	26	35	151	4	20250412	6.40	Weekend	Pending	0.00	6.00	11	50.10	4653.29	2
579	114	13	151	11	20250406	9.30	Regular	Approved	0.00	9.00	16	47.20	2423.25	2
580	127	12	85	9	20250120	6.70	Weekend	Approved	0.00	6.00	7	92.80	6652.83	2
581	88	18	174	9	20250411	4.40	Overtime	Pending	0.00	4.00	24	13.70	757.61	1
582	125	1	82	9	20250228	6.50	Regular	Pending	6.00	0.00	10	61.30	6710.51	2
583	25	29	88	11	20250330	10.00	Regular	Pending	0.00	10.00	57	7.40	611.91	2
584	79	33	79	6	20240912	2.10	Overtime	Rejected	0.00	2.00	8	23.20	1910.98	1
585	83	11	50	7	20240515	10.40	Weekend	Rejected	10.00	0.00	14	65.10	3516.05	2
586	168	27	200	12	20250429	3.50	Overtime	Approved	3.00	0.00	3	111.60	6443.78	1
587	95	10	79	6	20250528	4.90	Weekend	Approved	0.00	4.00	19	20.40	1264.39	1
588	145	26	196	7	20241215	9.40	Overtime	Pending	0.00	9.00	38	15.60	912.13	2
589	166	9	250	8	20241230	4.00	Weekend	Pending	0.00	4.00	4	108.70	6024.15	1
590	76	24	7	6	20240330	9.70	Overtime	Rejected	9.00	0.00	15	54.90	5883.08	2
591	56	33	113	5	20230904	1.80	Regular	Approved	0.00	1.00	2	105.40	8615.40	1
592	12	25	177	12	20250430	3.70	Weekend	Rejected	3.00	0.00	5	64.40	3639.89	1
593	15	22	71	9	20250101	5.80	Overtime	Pending	5.00	0.00	8	68.80	3618.88	1
594	84	27	212	3	20250414	7.50	Weekend	Pending	7.00	0.00	55	6.20	329.90	2
595	63	21	147	9	20230415	7.10	Overtime	Rejected	0.00	7.00	8	87.00	4745.85	2
596	180	21	246	6	20230602	9.20	Regular	Pending	0.00	9.00	40	13.60	1034.01	2
597	118	24	86	4	20240501	11.70	Overtime	Approved	11.00	0.00	85	2.10	109.05	2
598	36	8	165	7	20250331	5.40	Overtime	Pending	0.00	5.00	12	40.70	2825.39	1
599	132	24	5	10	20240331	12.00	Weekend	Approved	12.00	0.00	31	26.80	1729.14	2
600	73	22	163	2	20240803	7.20	Weekend	Pending	7.00	0.00	12	51.60	4338.01	2
601	147	30	157	11	20230321	9.30	Weekend	Approved	0.00	9.00	11	72.50	4320.28	2
602	116	10	167	6	20250416	3.00	Weekend	Approved	0.00	3.00	3	90.20	7667.00	1
603	6	26	148	5	20241215	7.90	Overtime	Pending	0.00	7.00	7	109.00	6431.00	2
604	110	10	67	4	20250519	8.40	Overtime	Rejected	0.00	8.00	55	7.00	464.73	2
605	148	23	229	12	20250418	2.70	Regular	Pending	0.00	2.00	9	26.00	2199.86	1
606	7	35	155	1	20250505	2.40	Overtime	Pending	0.00	2.00	3	75.60	6757.88	1
607	59	14	52	5	20250123	5.70	Overtime	Pending	0.00	5.00	6	86.80	6038.68	1
608	91	2	36	8	20241122	10.20	Overtime	Pending	0.00	10.00	11	81.50	5944.61	2
609	98	4	115	8	20240408	3.20	Overtime	Rejected	3.00	0.00	26	8.90	860.90	1
610	45	33	234	10	20241027	2.30	Regular	Pending	0.00	2.00	3	80.50	5081.96	1
611	82	27	49	4	20250406	9.80	Overtime	Approved	9.00	0.00	50	9.70	620.80	2
612	117	2	2	7	20250515	5.60	Regular	Approved	0.00	5.00	5	97.30	8414.50	1
613	17	28	243	11	20250503	3.50	Weekend	Pending	0.00	3.00	13	22.90	1414.30	1
614	121	2	244	5	20250426	8.10	Overtime	Pending	0.00	8.00	10	76.10	6578.08	2
615	46	1	33	9	20241209	2.50	Overtime	Pending	2.00	0.00	19	10.60	567.52	1
616	170	19	96	10	20250407	10.10	Overtime	Pending	10.00	0.00	11	82.90	4614.21	2
617	172	12	94	2	20241210	1.30	Regular	Approved	0.00	1.00	1	100.70	11574.46	1
618	68	21	8	1	20230503	1.30	Overtime	Pending	0.00	1.00	1	102.20	7751.87	1
619	105	3	139	7	20240411	7.60	Weekend	Pending	0.00	7.00	7	101.10	6104.42	2
620	90	15	24	7	20230619	2.20	Overtime	Approved	0.00	2.00	14	13.60	874.48	1
621	35	1	80	8	20250228	10.90	Overtime	Pending	10.00	0.00	84	2.00	103.32	2
622	158	7	123	8	20250513	10.10	Weekend	Pending	10.00	0.00	17	47.80	4084.99	2
623	37	15	169	2	20230704	8.90	Overtime	Rejected	0.00	8.00	25	26.90	1171.49	2
624	65	12	187	11	20241228	4.60	Overtime	Rejected	0.00	4.00	4	107.70	7029.58	1
625	34	21	109	6	20230317	7.40	Regular	Rejected	0.00	7.00	32	15.50	1468.32	2
626	162	4	204	4	20240311	1.20	Weekend	Pending	1.00	0.00	1	84.10	6156.12	1
627	42	26	83	1	20250416	6.30	Overtime	Pending	0.00	6.00	13	42.90	2503.22	2
628	116	14	117	10	20250218	7.00	Regular	Rejected	0.00	7.00	32	14.90	1266.50	2
629	87	12	66	6	20250121	9.50	Overtime	Rejected	0.00	9.00	10	85.20	4732.86	2
630	133	17	17	6	20250509	8.10	Weekend	Pending	0.00	8.00	7	108.40	8191.79	2
631	29	8	141	12	20250225	2.40	Overtime	Approved	0.00	2.00	2	105.40	8320.28	1
632	130	12	102	9	20241214	2.60	Weekend	Pending	0.00	2.00	3	85.90	8807.33	1
633	91	34	154	3	20230202	10.50	Weekend	Pending	0.00	10.00	29	25.60	1867.26	2
634	139	15	178	9	20230810	5.10	Regular	Rejected	0.00	5.00	5	101.70	4732.10	1
635	39	35	242	10	20250321	10.40	Overtime	Pending	0.00	10.00	70	4.50	435.74	2
636	76	25	231	9	20250421	10.80	Overtime	Approved	10.00	0.00	31	23.60	2528.98	2
637	1	5	65	12	20231219	8.30	Regular	Rejected	0.00	8.00	17	41.50	2723.23	2
638	16	27	36	3	20250526	10.00	Regular	Approved	10.00	0.00	11	81.70	4463.27	2
639	101	13	64	6	20241118	3.50	Overtime	Pending	0.00	3.00	5	63.20	4865.77	1
640	150	10	53	8	20250421	8.40	Overtime	Pending	0.00	8.00	8	96.40	7112.39	2
641	135	7	198	11	20250424	6.20	Weekend	Approved	6.00	0.00	7	80.80	5437.84	2
642	139	30	40	2	20230429	10.60	Regular	Approved	0.00	10.00	15	61.60	2866.25	2
643	29	30	110	10	20230316	10.60	Weekend	Approved	0.00	10.00	10	90.40	7136.18	2
644	134	7	23	12	20250425	11.60	Overtime	Pending	11.00	0.00	25	35.70	2841.72	2
645	180	28	108	1	20250408	10.50	Overtime	Rejected	0.00	10.00	23	36.10	2744.68	2
646	164	33	85	7	20240130	11.80	Regular	Pending	0.00	11.00	12	87.70	6216.18	2
647	63	32	57	10	20250217	8.30	Regular	Rejected	0.00	8.00	68	3.90	212.74	2
648	156	34	223	11	20221217	1.50	Regular	Rejected	0.00	1.00	1	101.80	4434.41	1
649	148	7	31	4	20250325	7.40	Weekend	Rejected	7.00	0.00	8	85.20	7208.77	2
650	11	23	166	8	20250319	7.30	Weekend	Pending	0.00	7.00	8	82.90	7834.05	2
651	172	2	56	10	20241207	1.30	Overtime	Pending	0.00	1.00	2	63.50	7298.69	1
652	8	30	218	5	20230503	10.00	Overtime	Approved	0.00	10.00	9	100.30	3905.68	2
653	71	29	201	1	20241211	6.00	Weekend	Approved	0.00	6.00	7	77.70	4393.93	1
654	54	21	190	7	20230508	9.60	Regular	Approved	0.00	9.00	16	51.60	4038.22	2
655	91	35	190	4	20250307	10.10	Regular	Rejected	0.00	10.00	17	51.10	3727.23	2
656	81	32	164	3	20250121	3.20	Weekend	Approved	0.00	3.00	6	54.00	2543.40	1
657	93	11	246	3	20240801	1.20	Regular	Rejected	1.00	0.00	5	21.60	1023.19	1
658	144	35	46	7	20250415	8.70	Regular	Pending	0.00	8.00	19	36.60	3464.19	2
659	68	10	184	6	20250516	4.90	Regular	Approved	0.00	4.00	16	25.40	1926.59	1
660	158	6	83	4	20250411	10.10	Regular	Rejected	0.00	10.00	21	39.10	3341.49	2
661	7	32	58	12	20241030	3.70	Regular	Approved	0.00	3.00	5	76.50	6838.34	1
662	38	1	76	4	20241105	10.40	Overtime	Approved	10.00	0.00	9	109.60	12074.63	2
663	106	12	218	9	20250202	5.40	Weekend	Approved	0.00	5.00	5	104.90	5389.76	1
664	68	28	95	6	20250425	4.50	Overtime	Pending	0.00	4.00	19	18.90	1433.56	1
665	83	16	204	9	20250206	2.10	Weekend	Rejected	2.00	0.00	2	83.20	4493.63	1
666	27	15	185	6	20240224	10.00	Regular	Approved	0.00	10.00	76	3.10	165.57	2
667	118	29	128	10	20250206	1.70	Regular	Pending	0.00	1.00	7	22.30	1158.04	1
668	89	31	223	12	20231026	1.70	Overtime	Pending	0.00	1.00	2	101.60	8137.14	1
669	146	17	243	12	20250319	8.80	Overtime	Approved	0.00	8.00	33	17.60	838.11	2
670	102	14	170	8	20250302	6.90	Weekend	Approved	0.00	6.00	6	107.00	6430.70	2
671	37	35	175	10	20250307	10.50	Weekend	Pending	0.00	10.00	33	21.60	940.68	2
672	151	8	199	2	20250518	1.70	Overtime	Rejected	0.00	1.00	1	118.10	9212.98	1
673	64	12	214	3	20241123	8.10	Overtime	Rejected	0.00	8.00	42	11.20	780.86	2
674	25	26	147	12	20250323	9.90	Overtime	Rejected	0.00	9.00	11	84.20	6962.50	2
675	47	7	80	6	20250301	8.80	Overtime	Approved	8.00	0.00	68	4.10	201.51	2
676	103	13	59	6	20250414	8.00	Overtime	Approved	0.00	8.00	11	65.00	4778.15	2
677	6	4	143	1	20240514	5.10	Regular	Pending	5.00	0.00	15	29.40	1734.60	1
678	2	21	99	5	20230215	9.80	Weekend	Rejected	0.00	9.00	10	85.10	4443.92	2
679	45	13	163	10	20250307	3.00	Regular	Approved	0.00	3.00	5	55.80	3522.65	1
680	154	24	147	3	20240401	8.80	Regular	Rejected	8.00	0.00	9	85.30	4079.90	2
681	8	3	240	9	20240415	11.30	Overtime	Approved	0.00	11.00	13	72.90	2838.73	2
682	152	34	43	2	20230116	3.10	Regular	Rejected	0.00	3.00	17	14.80	969.10	1
683	169	25	201	8	20250313	8.40	Regular	Approved	8.00	0.00	10	75.30	7406.51	2
684	62	32	49	7	20240731	4.90	Overtime	Rejected	0.00	4.00	25	14.60	1120.26	1
685	134	6	170	11	20250208	11.00	Weekend	Rejected	0.00	11.00	10	102.90	8190.84	2
686	140	13	73	6	20241204	5.90	Regular	Approved	0.00	5.00	7	74.50	3693.71	1
687	104	28	97	2	20250527	1.30	Regular	Approved	0.00	1.00	1	108.20	5704.30	1
688	79	32	202	5	20240807	6.80	Regular	Pending	0.00	6.00	23	22.70	1869.80	2
689	151	35	45	11	20250307	9.10	Weekend	Pending	0.00	9.00	9	96.40	7520.16	2
690	99	13	91	9	20241113	10.10	Weekend	Approved	0.00	10.00	9	102.10	7524.77	2
691	131	24	175	12	20240210	11.00	Regular	Approved	11.00	0.00	34	21.10	877.34	2
692	82	5	183	4	20231118	3.30	Weekend	Rejected	0.00	3.00	3	93.70	5996.80	1
693	53	8	237	5	20241213	10.90	Weekend	Approved	0.00	10.00	34	21.60	1875.31	2
694	59	24	235	7	20240210	2.70	Weekend	Pending	2.00	0.00	5	50.70	3527.20	1
695	109	20	53	11	20250119	11.10	Overtime	Rejected	11.00	0.00	11	93.70	6732.34	2
696	97	18	216	4	20250407	3.80	Regular	Rejected	0.00	3.00	4	88.90	8041.89	1
697	179	29	33	11	20241020	1.80	Regular	Pending	0.00	1.00	14	11.30	623.65	1
698	18	12	138	6	20241211	11.40	Overtime	Rejected	0.00	11.00	53	10.30	487.50	2
699	73	35	74	5	20250515	7.30	Regular	Pending	0.00	7.00	15	41.30	3472.09	2
700	23	32	52	3	20250401	12.00	Overtime	Approved	0.00	12.00	13	80.50	5555.30	2
701	10	25	48	2	20250526	9.90	Regular	Approved	9.00	0.00	11	79.60	8745.65	2
702	37	29	153	1	20250312	9.40	Regular	Pending	0.00	9.00	20	37.40	1628.77	2
703	146	1	243	3	20250126	10.50	Overtime	Pending	10.00	0.00	40	15.90	757.16	2
704	165	4	101	7	20240307	11.40	Weekend	Pending	11.00	0.00	56	9.00	600.66	2
705	86	29	7	8	20240802	10.30	Weekend	Rejected	0.00	10.00	16	54.30	5249.72	2
706	37	21	15	2	20230224	5.50	Weekend	Pending	0.00	5.00	8	64.80	2822.04	1
707	83	24	10	3	20240218	8.50	Regular	Approved	8.00	0.00	8	92.20	4979.72	2
708	100	8	220	4	20250521	1.40	Weekend	Pending	0.00	1.00	5	27.50	2457.12	1
709	147	25	73	11	20250516	5.30	Weekend	Pending	5.00	0.00	7	75.10	4475.21	1
710	89	30	123	3	20230528	6.90	Overtime	Pending	0.00	6.00	12	51.00	4084.59	2
711	100	17	226	3	20250502	9.10	Overtime	Approved	0.00	9.00	10	81.40	7273.09	2
712	106	35	219	4	20250318	2.40	Weekend	Approved	0.00	2.00	2	110.20	5662.08	1
713	108	27	118	12	20250522	5.90	Overtime	Approved	5.00	0.00	6	85.40	7843.99	1
714	171	26	35	12	20250428	3.30	Regular	Rejected	0.00	3.00	8	37.10	2644.12	1
715	169	24	231	8	20240415	10.50	Overtime	Approved	10.00	0.00	31	23.90	2350.80	2
716	101	10	121	2	20250516	8.20	Overtime	Rejected	0.00	8.00	15	48.00	3695.52	2
717	56	22	142	3	20250529	5.20	Weekend	Approved	5.00	0.00	8	59.80	4888.05	1
718	7	14	99	10	20250126	4.00	Weekend	Rejected	0.00	4.00	4	90.90	8125.55	1
719	165	26	148	4	20250121	5.50	Overtime	Pending	0.00	5.00	5	111.40	7434.84	1
720	125	21	157	10	20230217	8.40	Regular	Pending	0.00	8.00	10	73.40	8035.10	2
721	85	6	81	6	20241209	9.20	Regular	Approved	0.00	9.00	12	67.20	6480.77	2
722	160	21	150	8	20230609	4.70	Regular	Approved	0.00	4.00	4	101.60	6683.25	1
723	39	11	107	2	20241116	11.00	Overtime	Pending	11.00	0.00	30	25.40	2459.48	2
724	180	18	177	4	20250102	8.30	Regular	Approved	0.00	8.00	12	59.80	4546.59	2
725	35	25	122	7	20250429	2.90	Regular	Rejected	2.00	0.00	15	16.60	857.56	1
726	113	12	115	1	20250121	11.40	Weekend	Approved	0.00	11.00	94	0.70	26.26	2
727	95	5	46	3	20240123	4.30	Overtime	Pending	0.00	4.00	9	41.00	2541.18	1
728	163	21	75	12	20230301	4.90	Overtime	Pending	0.00	4.00	4	109.20	13100.72	1
729	44	24	218	5	20240229	6.60	Weekend	Pending	6.00	0.00	6	103.70	9077.90	2
730	14	16	180	5	20250313	5.90	Overtime	Approved	5.00	0.00	12	42.70	2284.45	1
731	169	6	86	9	20240913	2.40	Weekend	Pending	0.00	2.00	17	11.40	1121.30	1
732	78	25	52	8	20250416	5.30	Weekend	Rejected	5.00	0.00	6	87.20	7256.78	1
733	86	24	206	9	20240515	5.70	Weekend	Approved	5.00	0.00	26	15.90	1537.21	1
734	67	13	126	5	20250107	1.90	Overtime	Rejected	0.00	1.00	2	77.70	7350.42	1
735	131	8	6	3	20250108	3.70	Regular	Approved	0.00	3.00	3	115.70	4810.81	1
736	23	5	3	12	20230316	9.10	Overtime	Rejected	0.00	9.00	10	78.70	5431.09	2
737	162	22	202	11	20240819	7.70	Regular	Rejected	7.00	0.00	26	21.80	1595.76	2
738	48	6	184	2	20240829	5.80	Weekend	Pending	0.00	5.00	19	24.50	1962.94	1
739	100	21	161	9	20230329	6.20	Regular	Rejected	0.00	6.00	6	101.40	9060.09	2
740	121	19	188	11	20250522	10.50	Regular	Approved	10.00	0.00	9	108.40	9370.10	2
741	21	12	250	4	20241223	2.60	Weekend	Rejected	0.00	2.00	2	110.10	10340.59	1
742	180	5	49	3	20230821	9.30	Regular	Pending	0.00	9.00	48	10.20	775.51	2
743	154	27	130	11	20250501	3.40	Overtime	Approved	3.00	0.00	7	47.50	2271.92	1
744	168	17	73	3	20250324	1.70	Overtime	Approved	0.00	1.00	2	78.70	4544.14	1
745	159	28	21	11	20250522	1.10	Weekend	Rejected	0.00	1.00	2	71.20	6525.48	1
746	179	5	146	5	20230820	6.00	Weekend	Approved	0.00	6.00	11	46.60	2571.85	1
747	126	21	140	12	20230328	3.50	Regular	Pending	0.00	3.00	4	79.30	5295.65	1
748	120	30	84	7	20230530	10.60	Overtime	Approved	0.00	10.00	11	83.60	7338.41	2
749	108	2	224	3	20250511	4.50	Weekend	Pending	0.00	4.00	5	94.10	8643.08	1
750	112	12	39	10	20241213	3.40	Regular	Approved	0.00	3.00	34	6.70	298.95	1
751	87	13	6	8	20250208	2.70	Weekend	Approved	0.00	2.00	2	116.70	6482.68	1
752	156	32	111	7	20240929	6.40	Weekend	Pending	0.00	6.00	8	72.40	3153.74	2
753	18	21	181	8	20230423	2.60	Weekend	Approved	0.00	2.00	4	61.90	2929.73	1
754	126	1	245	5	20250410	2.70	Weekend	Approved	2.00	0.00	2	106.00	7078.68	1
755	157	8	154	3	20250426	4.10	Weekend	Approved	0.00	4.00	11	32.00	1960.32	1
756	95	31	17	1	20240327	5.10	Regular	Pending	0.00	5.00	4	111.40	6904.57	1
757	81	31	202	5	20240522	4.70	Overtime	Rejected	0.00	4.00	16	24.80	1168.08	1
758	83	15	182	10	20230915	9.90	Regular	Approved	0.00	9.00	44	12.50	675.12	2
759	81	33	226	2	20240614	9.30	Weekend	Approved	0.00	9.00	10	81.20	3824.52	2
760	119	18	18	8	20250313	9.60	Overtime	Rejected	0.00	9.00	49	10.00	582.50	2
761	122	16	58	11	20250105	4.60	Weekend	Approved	4.00	0.00	6	75.60	3340.01	1
762	82	32	81	10	20250410	3.20	Weekend	Pending	0.00	3.00	4	73.20	4684.80	1
763	76	4	189	4	20240424	9.80	Overtime	Pending	9.00	0.00	15	55.00	5893.80	2
764	180	1	77	5	20241222	2.60	Regular	Pending	2.00	0.00	3	100.00	7603.00	1
765	21	24	120	3	20240402	7.90	Weekend	Pending	7.00	0.00	8	89.80	8434.02	2
766	28	18	117	5	20250123	8.80	Overtime	Approved	0.00	8.00	40	13.10	916.34	2
767	83	2	32	1	20250113	7.10	Overtime	Pending	0.00	7.00	35	13.30	718.33	2
768	141	2	161	7	20250405	4.60	Regular	Approved	0.00	4.00	4	103.00	8655.09	1
769	165	19	83	10	20250516	1.40	Weekend	Pending	1.00	0.00	3	47.80	3190.17	1
770	128	5	238	2	20230520	2.70	Weekend	Pending	0.00	2.00	5	56.30	3973.09	1
771	24	24	249	6	20240319	1.90	Overtime	Pending	1.00	0.00	15	11.20	647.47	1
772	135	27	165	7	20250414	7.00	Regular	Pending	7.00	0.00	15	39.10	2631.43	2
773	67	15	62	1	20240226	1.30	Weekend	Rejected	0.00	1.00	2	57.20	5411.12	1
774	11	15	195	4	20230803	11.50	Regular	Rejected	0.00	11.00	39	17.90	1691.55	2
775	163	26	5	9	20250226	6.40	Weekend	Rejected	0.00	6.00	16	32.40	3887.03	2
776	11	13	151	1	20241223	3.50	Overtime	Pending	0.00	3.00	6	53.00	5008.50	1
777	149	24	131	3	20240326	3.30	Weekend	Pending	3.00	0.00	4	80.80	6115.75	1
778	69	24	131	7	20240225	10.20	Weekend	Approved	10.00	0.00	12	73.90	8012.24	2
779	67	26	31	11	20250225	6.00	Overtime	Rejected	0.00	6.00	6	86.60	8192.36	1
780	53	12	29	1	20250108	9.90	Weekend	Pending	0.00	9.00	26	28.60	2483.05	2
781	177	14	227	10	20250228	5.00	Regular	Rejected	0.00	5.00	7	71.40	6490.97	1
782	56	33	7	5	20230530	3.40	Regular	Approved	0.00	3.00	5	61.20	5002.49	1
783	84	30	101	10	20230315	11.10	Overtime	Rejected	0.00	11.00	54	9.30	494.85	2
784	20	7	227	1	20250210	7.80	Regular	Approved	7.00	0.00	10	68.60	4148.93	2
785	114	25	187	10	20250319	2.10	Overtime	Pending	2.00	0.00	2	110.20	5657.67	1
786	96	5	72	7	20230321	4.30	Regular	Pending	0.00	4.00	5	75.80	3861.25	1
787	117	14	31	11	20241220	10.70	Overtime	Pending	0.00	10.00	12	81.90	7082.71	2
788	61	30	223	10	20230411	4.00	Weekend	Rejected	0.00	4.00	4	99.30	6147.66	1
789	56	5	102	11	20230919	1.30	Overtime	Approved	0.00	1.00	1	87.20	7127.73	1
790	45	1	148	1	20250417	1.70	Overtime	Rejected	1.00	0.00	1	115.20	7272.58	1
791	52	18	7	11	20250211	11.60	Regular	Pending	0.00	11.00	18	53.00	4515.60	2
792	167	3	224	10	20240420	10.40	Weekend	Rejected	0.00	10.00	11	88.20	5965.85	2
793	13	19	94	2	20250524	5.00	Overtime	Rejected	5.00	0.00	5	97.00	7214.86	1
794	142	35	38	6	20250430	8.00	Overtime	Pending	0.00	8.00	15	44.50	2179.16	2
795	120	23	197	5	20241229	10.00	Overtime	Rejected	0.00	10.00	16	54.20	4757.68	2
796	111	6	155	5	20241106	4.70	Overtime	Rejected	0.00	4.00	6	73.30	6160.13	1
797	11	22	130	11	20240908	7.60	Weekend	Rejected	7.00	0.00	15	43.30	4091.85	2
798	147	9	209	4	20250114	8.60	Regular	Approved	0.00	8.00	8	102.90	6131.81	2
799	134	7	148	1	20250311	11.30	Weekend	Pending	11.00	0.00	10	105.60	8405.76	2
800	126	8	84	12	20250317	7.00	Overtime	Rejected	0.00	7.00	7	87.20	5823.22	2
801	57	23	192	7	20250517	9.30	Regular	Pending	0.00	9.00	12	65.60	3922.22	2
802	40	13	184	1	20250522	11.70	Regular	Approved	0.00	11.00	39	18.60	969.99	2
803	178	20	62	7	20240930	10.10	Weekend	Rejected	10.00	0.00	17	48.40	2622.31	2
804	7	2	8	5	20241121	3.30	Weekend	Pending	0.00	3.00	3	100.20	8956.88	1
805	31	28	242	6	20250516	1.10	Weekend	Approved	0.00	1.00	7	13.80	1634.75	1
806	54	20	110	10	20241212	11.10	Weekend	Rejected	11.00	0.00	11	89.90	7035.57	2
807	9	32	82	6	20240725	3.80	Overtime	Approved	0.00	3.00	6	64.00	5360.00	1
808	109	23	243	11	20250327	11.90	Overtime	Pending	0.00	11.00	45	14.50	1041.82	2
809	122	17	140	2	20250326	3.70	Weekend	Rejected	0.00	3.00	4	79.10	3494.64	1
810	98	22	62	10	20250221	1.40	Overtime	Rejected	1.00	0.00	2	57.10	5523.28	1
811	56	27	25	1	20250411	7.50	Weekend	Pending	7.00	0.00	8	84.10	6874.33	2
812	18	33	47	8	20240223	8.70	Overtime	Rejected	0.00	8.00	13	58.70	2778.27	2
813	65	8	179	9	20250416	2.90	Overtime	Approved	0.00	2.00	6	46.10	3008.95	1
814	75	22	110	2	20240913	11.70	Regular	Pending	11.00	0.00	12	89.30	5280.31	2
815	2	25	199	12	20250521	11.00	Overtime	Pending	11.00	0.00	9	108.80	5681.54	2
816	88	32	59	12	20250222	9.90	Regular	Pending	0.00	9.00	14	63.10	3489.43	2
817	155	2	113	8	20250123	9.70	Overtime	Pending	0.00	9.00	9	97.50	4832.10	2
818	163	35	28	7	20250327	1.40	Overtime	Rejected	0.00	1.00	6	24.00	2879.28	1
819	17	6	68	11	20250227	6.20	Weekend	Pending	0.00	6.00	17	30.00	1852.80	2
820	31	2	42	2	20250317	3.10	Regular	Approved	0.00	3.00	3	94.60	11206.32	1
821	143	17	123	2	20250408	7.40	Regular	Rejected	0.00	7.00	13	50.50	2686.09	2
822	38	20	35	12	20250110	5.30	Overtime	Pending	5.00	0.00	13	35.10	3866.97	1
823	29	34	171	5	20230207	6.80	Overtime	Pending	0.00	6.00	6	109.00	8604.46	2
824	123	14	49	11	20250413	6.30	Regular	Pending	0.00	6.00	32	13.20	1053.49	2
825	38	9	220	9	20240724	10.50	Regular	Approved	0.00	10.00	36	18.40	2027.13	2
826	145	11	64	11	20250309	5.50	Weekend	Approved	5.00	0.00	8	61.20	3578.36	1
827	105	4	193	7	20240222	10.60	Overtime	Pending	10.00	0.00	14	62.80	3791.86	2
828	101	29	156	4	20240901	6.30	Weekend	Approved	0.00	6.00	8	68.00	5235.32	2
829	62	34	74	8	20230327	1.80	Weekend	Pending	0.00	1.00	4	46.80	3590.96	1
830	38	3	95	5	20240224	4.10	Weekend	Approved	0.00	4.00	18	19.30	2126.28	1
831	79	31	131	8	20240225	9.30	Weekend	Rejected	0.00	9.00	11	74.80	6161.28	2
832	121	22	24	12	20250303	11.70	Weekend	Rejected	11.00	0.00	74	4.10	354.40	2
833	65	18	240	5	20250215	7.50	Regular	Approved	0.00	7.00	9	76.70	5006.21	2
834	62	13	90	5	20241219	10.10	Weekend	Rejected	0.00	10.00	9	103.90	7972.25	2
835	154	28	172	11	20250419	9.50	Regular	Rejected	0.00	9.00	32	19.80	947.03	2
836	139	21	53	8	20230324	2.30	Weekend	Approved	0.00	2.00	2	102.50	4769.32	1
837	154	22	47	11	20250307	5.10	Overtime	Approved	5.00	0.00	8	62.30	2979.81	1
838	138	22	38	5	20250502	1.80	Regular	Approved	1.00	0.00	3	50.70	3009.04	1
839	1	5	49	5	20231118	6.00	Weekend	Rejected	0.00	6.00	31	13.50	885.87	1
840	51	18	14	7	20250513	11.80	Weekend	Pending	0.00	11.00	63	7.00	602.98	2
841	81	8	36	3	20250112	5.00	Regular	Pending	0.00	5.00	5	86.70	4083.57	1
842	28	35	69	3	20250506	2.10	Weekend	Rejected	0.00	2.00	12	15.00	1049.25	1
843	170	4	3	2	20240331	11.70	Weekend	Approved	11.00	0.00	13	76.10	4235.73	2
844	60	15	159	10	20240304	9.30	Weekend	Approved	0.00	9.00	8	104.90	9278.40	2
845	6	21	196	4	20230323	9.90	Overtime	Pending	0.00	9.00	40	15.10	890.90	2
846	42	6	147	12	20250113	9.90	Regular	Pending	0.00	9.00	11	84.20	4913.07	2
847	57	16	118	10	20250216	10.80	Regular	Approved	10.00	0.00	12	80.50	4813.09	2
848	172	20	112	10	20250220	7.60	Overtime	Approved	7.00	0.00	63	4.50	517.23	2
849	21	27	183	8	20250521	2.70	Overtime	Rejected	2.00	0.00	3	94.30	8856.66	1
850	139	18	53	11	20250408	5.80	Weekend	Approved	0.00	5.00	6	99.00	4606.47	1
851	130	25	215	8	20250515	3.30	Regular	Rejected	3.00	0.00	6	50.30	5157.26	1
852	44	26	54	4	20250304	4.90	Overtime	Pending	0.00	4.00	9	52.40	4587.10	1
853	98	31	246	1	20240728	11.30	Regular	Rejected	0.00	11.00	50	11.50	1112.39	2
854	6	25	147	6	20250414	5.20	Overtime	Approved	5.00	0.00	6	88.90	5245.10	1
855	23	28	66	6	20250424	4.00	Overtime	Approved	0.00	4.00	4	90.70	6259.21	1
856	150	34	154	9	20230406	3.20	Regular	Approved	0.00	3.00	9	32.90	2427.36	1
857	24	11	24	10	20250208	7.10	Overtime	Pending	7.00	0.00	45	8.70	502.95	2
858	116	10	76	3	20250509	4.10	Regular	Pending	0.00	4.00	3	115.90	9851.50	1
859	134	5	60	2	20240121	1.60	Weekend	Rejected	0.00	1.00	1	108.20	8612.72	1
860	109	11	61	1	20240528	7.60	Regular	Pending	7.00	0.00	10	68.20	4900.17	2
861	46	35	32	8	20250406	9.40	Weekend	Pending	0.00	9.00	46	11.00	588.94	2
862	63	1	84	3	20250515	4.00	Regular	Rejected	4.00	0.00	4	90.20	4920.41	1
863	101	9	43	1	20241015	2.70	Regular	Pending	0.00	2.00	15	15.20	1170.25	1
864	147	18	119	4	20250330	2.90	Regular	Rejected	0.00	2.00	5	60.70	3617.11	1
865	18	25	35	1	20250404	6.10	Overtime	Rejected	6.00	0.00	15	34.30	1623.42	2
866	135	30	247	11	20230614	4.90	Weekend	Rejected	0.00	4.00	7	65.70	4421.61	1
867	65	34	240	7	20221023	6.50	Overtime	Pending	0.00	6.00	8	77.70	5071.48	2
868	19	24	216	5	20240219	7.60	Overtime	Approved	7.00	0.00	8	85.10	7606.24	2
869	7	21	125	4	20230212	3.40	Weekend	Pending	0.00	3.00	4	86.00	7687.54	1
870	167	20	102	4	20240820	1.20	Regular	Approved	1.00	0.00	1	87.30	5904.97	1
871	120	30	96	4	20230530	2.40	Regular	Pending	0.00	2.00	3	90.60	7952.87	1
872	76	24	14	6	20240404	11.00	Weekend	Approved	11.00	0.00	59	7.80	835.85	2
873	91	33	142	8	20230628	11.30	Overtime	Pending	0.00	11.00	17	53.70	3916.88	2
874	80	33	43	1	20230829	2.60	Weekend	Rejected	0.00	2.00	15	15.30	1350.07	1
875	131	14	162	9	20250318	1.30	Overtime	Approved	0.00	1.00	2	60.80	2528.06	1
876	89	21	73	6	20230221	9.80	Weekend	Pending	0.00	9.00	12	70.60	5654.35	2
877	111	33	10	11	20241017	1.70	Regular	Approved	0.00	1.00	2	99.00	8319.96	1
878	163	18	37	3	20250123	2.00	Overtime	Approved	0.00	2.00	3	65.60	7870.03	1
879	12	20	4	3	20240902	5.60	Regular	Approved	5.00	0.00	13	38.50	2176.02	1
880	110	17	235	4	20250316	11.90	Regular	Pending	0.00	11.00	22	41.50	2755.18	2
881	17	15	120	3	20240124	2.30	Weekend	Approved	0.00	2.00	2	95.40	5891.90	1
882	158	24	218	8	20240309	7.30	Weekend	Rejected	7.00	0.00	7	103.00	8802.38	2
883	135	10	171	11	20250527	7.50	Weekend	Approved	0.00	7.00	6	108.30	7288.59	2
884	58	2	112	8	20241230	4.60	Weekend	Approved	0.00	4.00	38	7.50	341.32	1
885	14	20	206	5	20240811	10.10	Weekend	Pending	10.00	0.00	47	11.50	615.25	2
886	64	30	232	3	20230226	8.70	Weekend	Approved	0.00	8.00	12	64.50	4496.94	2
887	108	22	77	2	20241028	2.80	Overtime	Rejected	2.00	0.00	3	99.80	9166.63	1
888	15	28	104	7	20250414	5.60	Regular	Approved	0.00	5.00	7	76.80	4039.68	1
889	79	16	125	8	20250416	7.50	Overtime	Approved	7.00	0.00	8	81.90	6746.10	2
890	63	11	87	3	20241220	4.60	Overtime	Pending	4.00	0.00	5	83.10	4533.10	1
891	3	10	139	7	20250513	10.90	Weekend	Rejected	0.00	10.00	10	97.80	8732.56	2
892	1	31	46	1	20231019	4.20	Overtime	Rejected	0.00	4.00	9	41.10	2696.98	1
893	171	6	11	3	20250202	4.60	Regular	Rejected	0.00	4.00	11	38.40	2736.77	1
894	158	1	211	4	20250521	2.90	Overtime	Approved	2.00	0.00	12	20.50	1751.93	1
895	158	34	19	10	20221122	2.50	Overtime	Rejected	0.00	2.00	3	79.10	6759.89	1
896	165	33	25	8	20240102	8.60	Regular	Approved	0.00	8.00	9	83.00	5539.42	2
897	178	31	208	8	20240211	11.50	Overtime	Approved	0.00	11.00	29	28.70	1554.97	2
898	108	16	204	5	20250329	3.30	Overtime	Pending	3.00	0.00	4	82.00	7531.70	1
899	21	4	151	2	20240306	2.20	Overtime	Pending	2.00	0.00	4	54.30	5099.86	1
900	73	22	177	6	20250418	3.60	Overtime	Approved	3.00	0.00	5	64.50	5422.51	1
901	54	31	168	1	20240214	2.70	Regular	Approved	0.00	2.00	8	32.40	2535.62	1
902	65	25	48	8	20250427	8.20	Overtime	Rejected	8.00	0.00	9	81.30	5306.45	2
903	35	21	191	12	20230527	8.20	Weekend	Rejected	0.00	8.00	10	75.30	3890.00	2
904	65	27	24	8	20250507	2.60	Regular	Pending	2.00	0.00	16	13.20	861.56	1
905	72	13	185	3	20250214	1.40	Regular	Rejected	0.00	1.00	11	11.70	1037.67	1
906	158	24	87	1	20240218	6.30	Weekend	Pending	6.00	0.00	7	81.40	6956.44	2
907	175	33	71	9	20240621	10.80	Weekend	Rejected	0.00	10.00	14	63.80	6033.57	2
908	112	3	117	12	20240320	7.00	Weekend	Approved	0.00	7.00	32	14.90	664.84	2
909	5	27	151	11	20250403	6.20	Overtime	Approved	6.00	0.00	11	50.30	3493.34	2
910	81	15	116	5	20231017	10.80	Regular	Pending	0.00	10.00	23	37.20	1752.12	2
911	102	17	2	9	20250414	1.40	Overtime	Pending	0.00	1.00	1	101.50	6100.15	1
912	13	5	206	5	20231209	10.00	Weekend	Approved	0.00	10.00	46	11.60	862.81	2
913	154	4	128	10	20240315	6.90	Weekend	Approved	6.00	0.00	29	17.10	817.89	2
914	100	22	46	9	20250527	3.20	Weekend	Approved	3.00	0.00	7	42.10	3761.63	1
915	123	2	26	3	20250501	9.00	Regular	Rejected	0.00	9.00	15	49.80	3974.54	2
916	107	11	232	7	20240601	9.00	Overtime	Pending	9.00	0.00	12	64.20	4997.33	2
917	80	35	178	9	20250417	1.80	Regular	Pending	0.00	1.00	2	105.00	9265.20	1
918	62	5	200	5	20230609	2.20	Overtime	Approved	0.00	2.00	2	112.90	8662.82	1
919	131	8	124	11	20250518	4.10	Regular	Approved	0.00	4.00	5	81.20	3376.30	1
920	46	25	207	4	20250507	11.40	Weekend	Pending	11.00	0.00	11	88.30	4727.58	2
921	17	11	38	6	20240510	6.70	Weekend	Rejected	6.00	0.00	13	45.80	2828.61	2
922	8	22	219	7	20250202	2.10	Weekend	Approved	2.00	0.00	2	110.50	4302.87	1
923	159	31	199	10	20240828	8.70	Weekend	Pending	0.00	8.00	7	111.10	10182.32	2
924	143	30	100	6	20230506	3.20	Regular	Pending	0.00	3.00	24	10.10	537.22	1
925	147	23	5	11	20250225	8.10	Overtime	Rejected	0.00	8.00	21	30.70	1829.41	2
926	119	6	35	2	20250521	7.20	Regular	Rejected	0.00	7.00	18	33.20	1933.90	2
927	142	22	31	10	20240712	9.60	Weekend	Approved	9.00	0.00	10	83.00	4064.51	2
928	76	3	220	2	20240112	11.30	Weekend	Pending	0.00	11.00	39	17.60	1886.02	2
929	40	18	88	7	20241223	11.70	Overtime	Pending	0.00	11.00	67	5.70	297.25	2
930	105	2	7	5	20250113	3.00	Regular	Pending	0.00	3.00	5	61.60	3719.41	1
931	93	8	25	5	20250307	4.50	Regular	Pending	0.00	4.00	5	87.10	4125.93	1
932	60	4	71	5	20240603	9.40	Weekend	Pending	9.00	0.00	13	65.20	5766.94	2
933	142	20	26	7	20250123	11.20	Overtime	Approved	11.00	0.00	19	47.60	2330.97	2
934	69	4	36	2	20240229	11.40	Weekend	Pending	11.00	0.00	12	80.30	8706.13	2
935	11	31	208	6	20240306	7.00	Overtime	Pending	0.00	7.00	17	33.20	3137.40	2
936	21	22	44	3	20250524	11.10	Weekend	Pending	11.00	0.00	15	62.90	5907.57	2
937	121	14	187	12	20250114	2.90	Weekend	Rejected	0.00	2.00	3	109.40	9456.54	1
938	2	34	225	5	20230205	9.70	Regular	Approved	0.00	9.00	12	70.90	3702.40	2
939	111	14	157	11	20250322	3.10	Weekend	Approved	0.00	3.00	4	78.70	6613.95	1
940	152	27	234	10	20250501	4.00	Weekend	Pending	4.00	0.00	5	78.80	5159.82	1
941	166	32	1	2	20250202	7.50	Weekend	Approved	0.00	7.00	13	51.80	2870.76	2
942	165	8	248	11	20250213	2.50	Regular	Pending	0.00	2.00	5	49.80	3323.65	1
943	19	26	35	4	20250222	11.60	Weekend	Pending	0.00	11.00	29	28.80	2574.14	2
944	179	1	106	2	20250126	3.30	Regular	Pending	3.00	0.00	3	102.50	5656.97	1
945	95	21	106	7	20230419	5.90	Regular	Rejected	0.00	5.00	6	99.90	6191.80	1
946	91	13	223	11	20250418	3.70	Overtime	Approved	0.00	3.00	4	99.60	7264.82	1
947	1	28	119	3	20250402	9.60	Regular	Rejected	0.00	9.00	15	54.00	3543.48	2
948	53	27	29	5	20250413	4.10	Regular	Approved	4.00	0.00	11	34.40	2986.61	1
949	136	5	151	8	20230904	4.30	Regular	Approved	0.00	4.00	8	52.20	2594.86	1
950	123	25	70	3	20250429	3.40	Regular	Pending	3.00	0.00	8	39.30	3136.53	1
951	99	15	243	9	20240201	8.10	Regular	Pending	0.00	8.00	31	18.30	1348.71	2
952	134	17	177	2	20250419	10.50	Weekend	Approved	0.00	10.00	15	57.60	4584.96	2
953	17	7	62	5	20250311	9.90	Weekend	Rejected	9.00	0.00	17	48.60	3001.54	2
954	161	32	136	1	20240924	11.50	Overtime	Rejected	0.00	11.00	12	83.30	5754.36	2
955	146	22	1	8	20241003	3.10	Weekend	Approved	3.00	0.00	5	56.20	2676.24	1
956	65	18	151	4	20250513	5.40	Weekend	Rejected	0.00	5.00	10	51.10	3335.30	1
957	98	31	160	4	20241109	3.70	Regular	Approved	0.00	3.00	4	90.20	8725.05	1
958	137	22	127	4	20250201	11.50	Regular	Rejected	11.00	0.00	24	37.20	2182.15	2
959	60	27	222	1	20250421	6.10	Weekend	Rejected	6.00	0.00	15	33.80	2989.61	2
960	35	15	189	4	20230905	5.10	Regular	Approved	0.00	5.00	8	59.70	3084.10	1
961	31	18	165	10	20250329	10.80	Regular	Approved	0.00	10.00	23	35.30	4181.64	2
962	24	17	203	10	20250523	9.20	Regular	Pending	0.00	9.00	28	24.00	1387.44	2
963	139	11	169	12	20250225	1.10	Overtime	Pending	1.00	0.00	3	34.70	1614.59	1
964	26	6	129	10	20241223	11.20	Overtime	Pending	0.00	11.00	51	10.90	1012.39	2
965	92	29	143	12	20240920	1.30	Regular	Rejected	0.00	1.00	4	33.20	1664.65	1
966	50	12	211	3	20241219	9.10	Weekend	Pending	0.00	9.00	39	14.30	611.18	2
967	51	9	76	8	20240702	8.30	Regular	Rejected	0.00	8.00	7	111.70	9621.84	2
968	53	24	161	5	20240502	5.80	Weekend	Pending	5.00	0.00	5	101.80	8838.28	1
969	122	25	2	3	20250415	1.40	Regular	Rejected	1.00	0.00	1	101.50	4484.27	1
970	28	6	196	3	20241214	1.80	Overtime	Pending	0.00	1.00	7	23.20	1622.84	1
971	69	34	183	9	20230303	6.80	Weekend	Rejected	0.00	6.00	7	90.20	9779.48	2
972	41	35	170	10	20250222	11.50	Overtime	Pending	0.00	11.00	10	102.40	4080.64	2
973	72	21	67	10	20230403	11.20	Regular	Pending	0.00	11.00	73	4.20	372.50	2
974	138	30	238	2	20230302	9.80	Regular	Pending	0.00	9.00	17	49.20	2920.02	2
975	144	31	102	11	20240604	8.80	Regular	Pending	0.00	8.00	10	79.70	7543.60	2
976	33	16	233	1	20250515	10.40	Weekend	Pending	10.00	0.00	13	70.80	6245.98	2
977	87	34	138	2	20221116	3.90	Weekend	Pending	0.00	3.00	18	17.80	988.79	1
978	110	32	218	4	20240919	9.80	Regular	Rejected	0.00	9.00	9	100.50	6672.20	2
979	160	29	19	7	20250518	7.00	Weekend	Approved	0.00	7.00	9	74.60	4907.19	2
980	87	2	9	1	20250509	1.30	Weekend	Rejected	0.00	1.00	2	57.30	3183.02	1
981	22	21	43	12	20230228	1.90	Regular	Approved	0.00	1.00	11	16.00	865.28	1
982	113	35	166	6	20250202	9.70	Weekend	Rejected	0.00	9.00	11	80.50	3019.56	2
983	91	21	98	11	20230309	9.70	Weekend	Rejected	0.00	9.00	10	91.80	6695.89	2
984	67	11	22	9	20240503	7.60	Weekend	Rejected	7.00	0.00	68	3.60	340.56	2
985	134	5	39	3	20230804	6.50	Regular	Approved	0.00	6.00	64	3.60	286.56	2
986	130	28	120	1	20250331	7.60	Regular	Rejected	0.00	7.00	8	90.10	9237.95	2
987	97	23	163	6	20241214	5.00	Weekend	Approved	0.00	5.00	9	53.80	4866.75	1
988	97	8	61	7	20250119	9.80	Weekend	Pending	0.00	9.00	13	66.00	5970.36	2
989	170	4	94	5	20240601	2.90	Weekend	Approved	2.00	0.00	3	99.10	5515.91	1
990	161	31	14	7	20231126	3.60	Weekend	Rejected	0.00	3.00	19	15.20	1050.02	1
991	5	34	48	3	20220927	1.70	Regular	Pending	0.00	1.00	2	87.80	6097.71	1
992	136	8	228	9	20250426	9.10	Overtime	Rejected	0.00	9.00	14	56.60	2813.59	2
993	141	31	128	4	20240502	3.10	Weekend	Pending	0.00	3.00	13	20.90	1756.23	1
994	103	18	63	3	20250525	1.70	Weekend	Approved	0.00	1.00	14	10.70	786.56	1
995	44	34	147	11	20230301	8.30	Overtime	Approved	0.00	8.00	9	85.80	7510.93	2
996	63	27	194	12	20250411	5.10	Weekend	Rejected	5.00	0.00	5	94.90	5176.80	1
997	80	17	22	8	20250321	10.00	Overtime	Rejected	0.00	10.00	89	1.20	105.89	2
998	96	19	222	1	20250207	5.40	Regular	Rejected	5.00	0.00	14	34.50	1757.43	1
999	140	12	76	4	20250221	1.30	Regular	Approved	0.00	1.00	1	118.70	5885.15	1
1000	72	19	132	10	20250506	6.60	Regular	Pending	6.00	0.00	7	86.90	7707.16	2
1001	62	33	133	3	20240224	4.60	Regular	Approved	0.00	4.00	9	48.00	3683.04	1
1002	173	22	10	5	20250519	1.60	Overtime	Pending	1.00	0.00	2	99.10	8290.71	1
1003	54	23	50	9	20250126	7.50	Weekend	Pending	0.00	7.00	10	68.00	5321.68	2
1004	37	7	24	2	20250509	7.60	Weekend	Approved	7.00	0.00	48	8.20	357.11	2
1005	140	4	156	4	20240318	7.50	Weekend	Rejected	7.00	0.00	10	66.80	3311.94	2
1006	35	26	165	6	20250209	1.40	Overtime	Pending	0.00	1.00	3	44.70	2309.20	1
1007	157	33	128	6	20240619	2.00	Weekend	Approved	0.00	2.00	8	22.00	1347.72	1
1008	3	12	54	1	20241123	7.40	Overtime	Approved	0.00	7.00	13	49.90	4455.57	2
1009	153	34	237	1	20221112	8.60	Overtime	Approved	0.00	8.00	26	23.90	2299.90	2
1010	68	19	211	10	20250121	11.60	Overtime	Pending	11.00	0.00	50	11.80	895.03	2
1011	101	24	157	6	20240222	10.70	Regular	Approved	10.00	0.00	13	71.10	5473.99	2
1012	135	19	28	9	20250306	3.50	Overtime	Rejected	3.00	0.00	14	21.90	1473.87	1
1013	151	9	194	7	20240805	2.90	Weekend	Pending	0.00	2.00	3	97.10	7574.77	1
1014	19	16	116	5	20250331	4.70	Regular	Pending	4.00	0.00	10	43.30	3870.15	1
1015	179	19	34	9	20250508	5.50	Weekend	Pending	5.00	0.00	18	25.40	1401.83	1
1016	87	16	127	7	20250424	5.80	Weekend	Pending	5.00	0.00	12	42.90	2383.10	1
1017	30	9	110	1	20250212	1.50	Regular	Pending	0.00	1.00	1	99.50	9282.36	1
1018	93	25	102	10	20250310	10.00	Regular	Approved	10.00	0.00	11	78.50	3718.54	2
1019	19	21	241	12	20230403	2.10	Regular	Pending	0.00	2.00	3	65.10	5818.64	1
1020	92	4	210	7	20240422	7.10	Overtime	Rejected	7.00	0.00	22	24.90	1248.49	2
1021	109	10	160	4	20250515	10.10	Overtime	Rejected	0.00	10.00	11	83.80	6021.03	2
1022	62	20	230	9	20240716	9.70	Overtime	Pending	9.00	0.00	9	103.10	7910.86	2
1023	123	34	35	7	20220922	3.30	Weekend	Approved	0.00	3.00	8	37.10	2960.95	1
1024	14	7	171	6	20250405	8.60	Regular	Rejected	8.00	0.00	7	107.20	5735.20	2
1025	145	5	206	5	20230803	7.30	Regular	Rejected	0.00	7.00	34	14.30	836.12	2
1026	150	11	104	10	20250213	7.30	Weekend	Approved	7.00	0.00	9	75.10	5540.88	2
1027	169	19	213	9	20250525	9.40	Weekend	Rejected	9.00	0.00	68	4.50	442.62	2
1028	23	34	76	3	20230126	9.60	Weekend	Approved	0.00	9.00	8	110.40	7618.70	2
1029	38	22	145	2	20241123	1.20	Weekend	Approved	1.00	0.00	2	75.30	8295.80	1
1030	45	13	28	3	20250518	9.90	Regular	Approved	0.00	9.00	39	15.50	978.51	2
1031	104	4	105	10	20240516	1.30	Weekend	Approved	1.00	0.00	1	113.50	5983.72	1
1032	118	27	249	1	20250521	2.90	Regular	Approved	2.00	0.00	22	10.20	529.69	1
1033	134	15	84	11	20231118	8.20	Weekend	Pending	0.00	8.00	9	86.00	6845.60	2
1034	73	1	230	6	20250212	10.80	Regular	Pending	10.00	0.00	10	102.00	8575.14	2
1035	88	2	141	3	20250202	7.50	Overtime	Rejected	0.00	7.00	7	100.30	5546.59	2
1036	170	18	24	9	20250311	7.30	Overtime	Approved	0.00	7.00	46	8.50	473.11	2
1037	4	31	208	7	20231001	8.40	Weekend	Pending	0.00	8.00	21	31.80	2302.64	2
1038	147	22	237	2	20241101	10.30	Overtime	Approved	10.00	0.00	32	22.20	1322.90	2
1039	151	20	218	9	20240922	7.90	Regular	Pending	7.00	0.00	7	102.40	7988.22	2
1040	123	15	1	1	20240204	5.80	Overtime	Approved	0.00	5.00	10	53.50	4269.84	1
1041	30	25	129	4	20250308	1.90	Regular	Rejected	1.00	0.00	9	20.20	1884.46	1
1042	13	5	97	9	20230407	7.70	Overtime	Pending	0.00	7.00	7	101.80	7571.88	2
1043	83	4	117	7	20240526	2.90	Weekend	Rejected	2.00	0.00	13	19.00	1026.19	1
1044	165	27	161	3	20250401	9.00	Regular	Rejected	9.00	0.00	8	98.60	6580.56	2
1045	127	29	114	10	20241119	5.30	Regular	Rejected	0.00	5.00	4	113.50	8136.81	1
1046	104	27	172	3	20250412	4.80	Weekend	Pending	4.00	0.00	16	24.50	1291.64	1
1047	161	31	237	7	20241126	1.50	Regular	Rejected	0.00	1.00	5	31.00	2141.48	1
1048	68	2	102	9	20250412	6.90	Regular	Pending	0.00	6.00	8	81.60	6189.36	2
1049	60	6	240	3	20250204	4.90	Regular	Pending	0.00	4.00	6	79.30	7014.09	1
1050	28	30	140	2	20230530	1.10	Regular	Rejected	0.00	1.00	1	81.70	5714.92	1
1051	1	25	29	4	20250422	3.60	Weekend	Rejected	3.00	0.00	9	34.90	2290.14	1
1052	127	35	147	6	20250315	2.30	Regular	Approved	0.00	2.00	2	91.80	6581.14	1
1053	79	17	152	1	20250406	10.50	Overtime	Pending	0.00	10.00	25	31.60	2602.89	2
1054	76	33	12	2	20240801	4.00	Regular	Pending	0.00	4.00	3	110.80	11873.33	1
1055	27	26	121	9	20250110	11.20	Overtime	Rejected	0.00	11.00	20	45.00	2403.45	2
1056	48	5	4	3	20230426	10.70	Weekend	Rejected	0.00	10.00	24	33.40	2676.01	2
1057	161	13	67	9	20250215	2.90	Weekend	Approved	0.00	2.00	19	12.50	863.50	1
1058	176	29	60	7	20241024	10.60	Weekend	Pending	0.00	10.00	10	99.20	8421.09	2
1059	140	21	105	1	20230505	3.50	Overtime	Rejected	0.00	3.00	3	111.30	5518.25	1
1060	104	8	117	8	20241227	5.40	Overtime	Pending	0.00	5.00	25	16.50	869.88	1
1061	4	24	196	1	20240324	6.90	Regular	Rejected	6.00	0.00	28	18.10	1310.62	2
1062	58	23	84	11	20250101	1.90	Overtime	Rejected	0.00	1.00	2	92.30	4200.57	1
1063	4	22	139	8	20240818	8.60	Overtime	Rejected	8.00	0.00	8	100.10	7248.24	2
1064	134	12	19	10	20241207	4.60	Overtime	Approved	0.00	4.00	6	77.00	6129.20	1
1065	143	35	198	11	20250301	3.60	Weekend	Rejected	0.00	3.00	4	83.40	4436.05	1
1066	41	9	229	1	20250120	4.60	Regular	Rejected	0.00	4.00	16	24.10	960.38	1
1067	170	35	111	12	20250412	8.90	Overtime	Rejected	0.00	8.00	11	69.90	3890.63	2
1068	77	22	217	12	20250504	6.60	Weekend	Pending	6.00	0.00	8	73.70	3401.25	2
1069	89	29	161	9	20250314	6.00	Regular	Rejected	0.00	6.00	6	101.60	8137.14	1
1070	92	12	61	9	20250110	5.90	Overtime	Pending	0.00	5.00	8	69.90	3504.79	1
1071	7	29	71	7	20240806	11.60	Regular	Rejected	0.00	11.00	16	63.00	5631.57	2
1072	127	35	127	7	20250405	2.60	Weekend	Rejected	0.00	2.00	5	46.10	3304.91	1
1073	40	9	82	9	20241111	3.20	Weekend	Pending	0.00	3.00	5	64.60	3368.89	1
1074	175	34	1	7	20230222	3.00	Weekend	Pending	0.00	3.00	5	56.30	5324.29	1
1075	8	24	194	7	20240324	9.00	Overtime	Rejected	9.00	0.00	9	91.00	3543.54	2
1076	8	8	43	5	20250429	2.90	Weekend	Approved	0.00	2.00	16	15.00	584.10	1
1077	65	12	240	9	20250109	6.10	Overtime	Pending	0.00	6.00	7	78.10	5097.59	2
1078	48	16	163	3	20250521	9.10	Overtime	Approved	9.00	0.00	15	49.70	3981.96	2
1079	50	35	246	10	20250525	2.10	Overtime	Pending	0.00	2.00	9	20.70	884.72	1
1080	48	35	195	6	20250428	11.90	Overtime	Pending	0.00	11.00	40	17.50	1402.10	2
1081	100	11	248	10	20240515	5.40	Weekend	Pending	5.00	0.00	10	46.90	4190.51	1
1082	88	34	156	11	20221214	2.10	Weekend	Pending	0.00	2.00	3	72.20	3992.66	1
1083	95	24	7	11	20240407	6.70	Overtime	Rejected	6.00	0.00	10	57.90	3588.64	2
1084	125	19	212	5	20250217	1.10	Overtime	Rejected	1.00	0.00	8	12.60	1379.32	1
1085	29	31	154	8	20231104	1.50	Weekend	Rejected	0.00	1.00	4	34.60	2731.32	1
1086	69	3	23	6	20240131	5.30	Regular	Approved	0.00	5.00	11	42.00	4553.64	1
1087	84	21	52	2	20230404	9.00	Overtime	Rejected	0.00	9.00	10	83.50	4443.04	2
1088	122	34	25	4	20230403	5.70	Overtime	Pending	0.00	5.00	6	85.90	3795.06	1
1089	39	7	73	2	20250211	9.50	Regular	Approved	9.00	0.00	12	70.90	6865.25	2
1090	179	34	122	9	20220926	7.70	Regular	Approved	0.00	7.00	39	11.80	651.24	2
1091	34	16	217	9	20250519	7.10	Overtime	Approved	7.00	0.00	9	73.20	6934.24	2
1092	85	28	107	1	20250506	10.50	Weekend	Rejected	0.00	10.00	29	25.90	2497.80	2
1093	138	29	72	5	20240921	2.50	Weekend	Approved	0.00	2.00	3	77.60	4605.56	1
1094	139	22	188	10	20250128	11.60	Overtime	Rejected	11.00	0.00	10	107.30	4992.67	2
1095	46	33	33	5	20230916	11.60	Weekend	Approved	0.00	11.00	89	1.50	80.31	2
1096	35	1	226	1	20241110	2.70	Overtime	Approved	2.00	0.00	3	87.80	4535.75	1
1097	19	16	34	11	20250203	9.80	Overtime	Pending	9.00	0.00	32	21.10	1885.92	2
1098	88	31	9	9	20231124	8.00	Overtime	Rejected	0.00	8.00	14	50.60	2798.18	2
1099	73	20	73	9	20241126	7.80	Overtime	Rejected	7.00	0.00	10	72.60	6103.48	2
1100	37	32	247	12	20241031	5.70	Weekend	Approved	0.00	5.00	8	64.90	2826.39	1
1101	165	27	39	12	20250326	2.40	Weekend	Rejected	2.00	0.00	24	7.70	513.90	1
1102	74	14	244	2	20250426	3.40	Regular	Rejected	0.00	3.00	4	80.80	8577.73	1
1103	35	13	215	2	20241202	3.20	Regular	Rejected	0.00	3.00	6	50.40	2603.66	1
1104	160	6	16	7	20240901	10.70	Weekend	Pending	0.00	10.00	20	43.30	2848.27	2
1105	41	14	184	9	20250410	4.80	Weekend	Pending	0.00	4.00	16	25.50	1016.18	1
1106	133	6	171	8	20241126	9.70	Overtime	Approved	0.00	9.00	8	106.10	8017.98	2
1107	93	18	124	3	20250311	2.70	Weekend	Pending	0.00	2.00	3	82.60	3912.76	1
1108	131	30	98	11	20230403	9.00	Overtime	Pending	0.00	9.00	9	92.50	3846.15	2
1109	113	8	166	8	20250125	1.70	Weekend	Pending	0.00	1.00	2	88.50	3319.64	1
1110	145	12	245	1	20241231	3.00	Regular	Rejected	0.00	3.00	3	105.70	6180.28	1
1111	106	11	245	2	20250227	5.70	Overtime	Rejected	5.00	0.00	5	103.00	5292.14	1
1112	164	20	61	9	20241202	2.60	Regular	Approved	2.00	0.00	3	73.20	5188.42	1
1113	148	35	53	6	20250407	11.30	Overtime	Approved	0.00	11.00	11	93.50	7911.03	2
1114	127	15	42	7	20231012	3.70	Regular	Rejected	0.00	3.00	4	94.00	6738.86	1
1115	148	32	157	12	20240907	3.00	Overtime	Rejected	0.00	3.00	4	78.80	6667.27	1
1116	1	12	147	3	20250115	1.80	Regular	Approved	0.00	1.00	2	92.30	6056.73	1
1117	135	32	185	2	20241027	6.40	Overtime	Pending	0.00	6.00	49	6.70	450.91	2
1118	34	10	8	11	20250418	2.50	Overtime	Approved	0.00	2.00	2	101.00	9567.73	1
1119	141	13	45	1	20241111	3.90	Weekend	Approved	0.00	3.00	4	101.60	8537.45	1
1120	133	33	130	10	20240808	4.80	Regular	Rejected	0.00	4.00	9	46.10	3483.78	1
1121	171	33	92	3	20240115	8.00	Overtime	Pending	0.00	8.00	12	56.20	4005.37	2
1122	52	2	72	5	20241221	11.10	Weekend	Pending	0.00	11.00	14	69.00	5878.80	2
1123	29	30	18	6	20230314	11.50	Weekend	Rejected	0.00	11.00	59	8.10	639.41	2
1124	6	10	165	10	20250422	9.60	Weekend	Rejected	0.00	9.00	21	36.50	2153.50	2
1125	24	20	51	8	20240923	8.20	Weekend	Rejected	8.00	0.00	7	106.30	6145.20	2
1126	2	27	121	2	20250421	8.60	Overtime	Pending	8.00	0.00	15	47.60	2485.67	2
1127	38	26	13	11	20250121	9.00	Regular	Pending	0.00	9.00	49	9.20	1013.56	2
1128	105	30	193	11	20230308	1.60	Weekend	Rejected	0.00	1.00	2	71.80	4335.28	1
1129	29	25	104	2	20250315	11.00	Regular	Pending	11.00	0.00	13	71.40	5636.32	2
1130	115	9	186	6	20241203	9.20	Weekend	Approved	0.00	9.00	14	57.00	4374.75	2
1131	160	14	10	5	20250508	3.10	Overtime	Approved	0.00	3.00	3	97.60	6420.13	1
1132	170	12	117	11	20250213	9.90	Weekend	Pending	0.00	9.00	45	12.00	667.92	2
1133	46	7	24	5	20250209	9.70	Weekend	Approved	9.00	0.00	61	6.10	326.59	2
1134	87	1	148	11	20250122	11.80	Regular	Rejected	11.00	0.00	10	105.10	5838.30	2
1135	5	13	180	6	20250128	8.90	Regular	Rejected	0.00	8.00	18	39.70	2757.17	2
1136	55	23	33	12	20250420	6.50	Regular	Pending	0.00	6.00	50	6.60	488.86	2
1137	31	10	71	4	20250509	11.30	Weekend	Approved	0.00	11.00	15	63.30	7498.52	2
1138	79	9	55	1	20240822	11.40	Weekend	Pending	0.00	11.00	12	85.80	7067.35	2
1139	14	28	32	6	20250415	6.30	Weekend	Approved	0.00	6.00	31	14.10	754.35	2
1140	154	4	114	12	20240519	11.60	Overtime	Approved	11.00	0.00	10	107.20	5127.38	2
1141	106	15	34	3	20231008	6.80	Regular	Approved	0.00	6.00	22	24.10	1238.26	2
1142	176	1	57	12	20250430	10.50	Regular	Pending	10.00	0.00	86	1.70	144.31	2
1143	158	24	233	7	20240408	7.20	Weekend	Approved	7.00	0.00	9	74.00	6324.04	2
1144	160	5	95	8	20240106	8.40	Overtime	Approved	0.00	8.00	36	15.00	986.70	2
1145	64	17	123	2	20250402	10.20	Overtime	Approved	0.00	10.00	18	47.70	3325.64	2
1146	12	4	197	2	20240529	9.60	Regular	Pending	9.00	0.00	15	54.60	3085.99	2
1147	142	15	26	8	20231207	4.00	Regular	Approved	0.00	4.00	7	54.80	2683.56	1
1148	140	1	133	2	20250526	9.00	Overtime	Approved	9.00	0.00	17	43.60	2161.69	2
1149	28	22	181	1	20250218	1.90	Weekend	Pending	1.00	0.00	3	62.60	4378.87	1
1150	64	4	119	12	20240317	4.70	Regular	Approved	4.00	0.00	7	58.90	4106.51	1
1151	126	20	52	7	20240828	2.30	Regular	Pending	2.00	0.00	2	90.20	6023.56	1
1152	47	23	137	9	20250514	4.90	Overtime	Rejected	0.00	4.00	4	114.70	5637.50	1
1153	128	2	53	2	20250314	1.10	Regular	Rejected	0.00	1.00	1	103.70	7318.11	1
1154	156	26	41	8	20250217	10.20	Overtime	Approved	0.00	10.00	49	10.70	466.09	2
1155	91	5	135	4	20230519	8.70	Overtime	Pending	0.00	8.00	13	57.30	4179.46	2
1156	104	27	109	2	20250504	11.60	Weekend	Rejected	11.00	0.00	51	11.30	595.74	2
1157	30	4	115	10	20240419	8.30	Regular	Approved	8.00	0.00	69	3.80	354.50	2
1158	150	16	140	9	20250122	10.00	Weekend	Rejected	10.00	0.00	12	72.80	5371.18	2
1159	147	1	81	4	20250419	12.00	Regular	Approved	12.00	0.00	16	64.40	3837.60	2
1160	66	33	10	10	20240317	8.10	Weekend	Approved	0.00	8.00	8	92.60	8390.49	2
1161	156	34	127	11	20221107	8.10	Regular	Approved	0.00	8.00	17	40.60	1768.54	2
1162	107	25	155	9	20250405	2.10	Overtime	Pending	2.00	0.00	3	75.90	5908.06	1
1163	74	4	125	8	20240430	3.90	Regular	Pending	3.00	0.00	4	85.50	9076.68	1
1164	47	14	189	12	20250423	8.40	Weekend	Approved	0.00	8.00	13	56.40	2772.06	2
1165	157	29	207	1	20240801	8.80	Overtime	Pending	0.00	8.00	9	90.90	5568.53	2
1166	7	14	120	1	20250423	6.10	Weekend	Pending	0.00	6.00	6	91.60	8188.12	2
1167	15	11	170	11	20250120	1.30	Weekend	Rejected	1.00	0.00	1	112.60	5922.76	1
1168	61	24	176	12	20240511	7.80	Weekend	Rejected	7.00	0.00	20	31.70	1962.55	2
1169	38	8	22	8	20241217	9.00	Weekend	Rejected	0.00	9.00	80	2.20	242.37	2
1170	170	33	8	2	20240629	10.80	Overtime	Rejected	0.00	10.00	10	92.70	5159.68	2
1171	116	23	134	9	20250529	11.20	Weekend	Approved	0.00	11.00	10	104.40	8874.00	2
1172	113	1	139	3	20241115	9.90	Overtime	Rejected	9.00	0.00	9	98.80	3705.99	2
1173	82	31	171	2	20241009	10.30	Regular	Approved	0.00	10.00	9	105.50	6752.00	2
1174	153	26	24	11	20250104	11.30	Weekend	Approved	0.00	11.00	72	4.50	433.04	2
1175	43	28	144	9	20250414	6.10	Overtime	Rejected	0.00	6.00	9	64.00	6462.08	2
1176	171	4	69	1	20240502	4.90	Weekend	Pending	4.00	0.00	29	12.20	869.49	1
1177	149	28	29	6	20250519	1.50	Weekend	Rejected	0.00	1.00	4	37.00	2800.53	1
1178	73	15	86	12	20231126	4.90	Overtime	Rejected	0.00	4.00	36	8.90	748.22	1
1179	47	19	164	1	20250525	11.20	Weekend	Rejected	11.00	0.00	20	46.00	2260.90	2
1180	99	35	64	12	20250228	11.30	Overtime	Pending	0.00	11.00	17	55.40	4082.98	2
1181	39	5	114	1	20230527	7.20	Regular	Approved	0.00	7.00	6	111.60	10806.23	2
1182	149	16	212	11	20250419	4.00	Weekend	Pending	4.00	0.00	29	9.70	734.19	1
1183	69	35	103	9	20250425	6.50	Weekend	Pending	0.00	6.00	8	70.40	7632.77	2
1184	67	26	123	3	20250427	5.90	Weekend	Pending	0.00	5.00	10	52.00	4919.20	1
1185	23	20	19	4	20250212	2.20	Weekend	Pending	2.00	0.00	3	79.40	5479.39	1
1186	53	27	28	4	20250422	6.20	Overtime	Pending	6.00	0.00	24	19.20	1666.94	2
1187	12	17	83	9	20250520	2.00	Overtime	Rejected	0.00	2.00	4	47.20	2667.74	1
1188	93	18	193	5	20250409	2.60	Regular	Rejected	0.00	2.00	4	70.80	3353.80	1
1189	167	3	224	4	20240403	4.20	Regular	Rejected	0.00	4.00	4	94.40	6385.22	1
1190	121	31	230	12	20230914	9.50	Regular	Rejected	0.00	9.00	8	103.30	8929.25	2
1191	140	35	245	12	20250126	10.50	Overtime	Rejected	0.00	10.00	10	98.20	4868.76	2
1192	21	29	70	7	20250319	10.30	Regular	Pending	0.00	10.00	24	32.40	3043.01	2
1193	101	25	243	5	20250507	5.60	Weekend	Rejected	5.00	0.00	21	20.80	1601.39	1
1194	179	26	179	10	20250405	4.40	Weekend	Approved	0.00	4.00	9	44.60	2461.47	1
1195	84	22	151	5	20241203	9.80	Regular	Pending	9.00	0.00	17	46.70	2484.91	2
1196	154	12	15	11	20250120	11.90	Regular	Rejected	0.00	11.00	17	58.40	2793.27	2
1197	90	8	19	8	20250101	5.60	Weekend	Pending	0.00	5.00	7	76.00	4886.80	1
1198	54	27	81	4	20250517	11.70	Weekend	Pending	11.00	0.00	15	64.70	5063.42	2
1199	84	24	154	1	20240324	6.30	Regular	Pending	6.00	0.00	17	29.80	1585.66	2
1200	35	20	136	10	20240917	3.00	Overtime	Approved	3.00	0.00	3	91.80	4742.39	1
\.


--
-- PostgreSQL database dump complete
--

