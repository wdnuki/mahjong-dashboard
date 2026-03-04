import functions_framework
from flask import jsonify
from google.cloud import bigquery

bq = bigquery.Client(project="mahjonganalyzer")

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

SQL_SUMMARY = """
SELECT
  FORMAT_DATE('%Y/%m/%d', KANRI_DATE) AS KANRI_DATE,
  SUMMARY
FROM `mahjonganalyzer.MM.V_HANCHANS_HEADER`
ORDER BY KANRI_DATE DESC, HANCHAN_ID DESC
LIMIT 20
"""

SQL_CUMULATIVE = """
WITH base AS (
  SELECT
    C.KANRI_DATE,
    U.NICK_NAME,
    A.POINT
  FROM `mahjonganalyzer.MM.J_HANCHANS_D` A
  JOIN `mahjonganalyzer.MM.J_HANCHANS_H` C
    ON A.HANCHAN_ID = C.HANCHAN_ID
  JOIN `mahjonganalyzer.MM.V_USERS` U
    ON A.LINE_USER_ID = U.LINE_USER_ID
  WHERE C.KANRI_DATE >= '2026-03-01'
),
daily AS (
  SELECT
    KANRI_DATE,
    NICK_NAME,
    SUM(POINT) AS DAILY_POINT
  FROM base
  GROUP BY KANRI_DATE, NICK_NAME
)
SELECT
  FORMAT_DATE('%Y/%m/%d', KANRI_DATE) AS KANRI_DATE,
  NICK_NAME,
  SUM(DAILY_POINT)
    OVER (PARTITION BY NICK_NAME ORDER BY KANRI_DATE)
    AS CUM_POINT
FROM daily
ORDER BY KANRI_DATE
"""

SQL_TOP_SCORE = """
SELECT
  FORMAT_DATE('%Y/%m/%d', C.KANRI_DATE) AS KANRI_DATE,
  U.NICK_NAME,
  A.POINT
FROM `mahjonganalyzer.MM.J_HANCHANS_D` A
JOIN `mahjonganalyzer.MM.J_HANCHANS_H` C
  ON A.HANCHAN_ID = C.HANCHAN_ID
JOIN `mahjonganalyzer.MM.V_USERS` U
  ON A.LINE_USER_ID = U.LINE_USER_ID
WHERE C.KANRI_DATE >= '2026-03-01'
ORDER BY A.POINT DESC
LIMIT 3
"""


def handle_summary(request):
    rows = bq.query(SQL_SUMMARY).result()
    data = [{"KANRI_DATE": r.KANRI_DATE, "SUMMARY": r.SUMMARY} for r in rows]
    return (jsonify(data), 200, CORS_HEADERS)


def handle_cumulative(request):
    rows = bq.query(SQL_CUMULATIVE).result()
    data = [
        {
            "KANRI_DATE": r.KANRI_DATE,
            "NICK_NAME": r.NICK_NAME,
            "CUM_POINT": float(r.CUM_POINT),
        }
        for r in rows
    ]
    return (jsonify(data), 200, CORS_HEADERS)


def handle_top_score(request):
    rows = bq.query(SQL_TOP_SCORE).result()
    data = [
        {
            "KANRI_DATE": r.KANRI_DATE,
            "NICK_NAME": r.NICK_NAME,
            "POINT": float(r.POINT),
        }
        for r in rows
    ]
    return (jsonify(data), 200, CORS_HEADERS)


@functions_framework.http
def app(request):
    if request.method == "OPTIONS":
        return ("", 204, CORS_HEADERS)
    try:
        path = request.path.rstrip("/")
        if path == "/kawaicup/cumulative":
            return handle_cumulative(request)
        elif path == "/kawaicup/top-score":
            return handle_top_score(request)
        else:
            return handle_summary(request)
    except Exception as e:
        return (jsonify({"error": str(e)}), 500, CORS_HEADERS)
