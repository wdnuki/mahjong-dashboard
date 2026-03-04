import functions_framework
from flask import jsonify
from google.cloud import bigquery

bq = bigquery.Client(project="mahjonganalyzer")

SQL = """
SELECT
  FORMAT_DATE('%Y/%m/%d', KANRI_DATE) AS KANRI_DATE,
  SUMMARY
FROM `mahjonganalyzer.MM.V_HANCHANS_HEADER`
ORDER BY KANRI_DATE DESC, HANCHAN_ID DESC
LIMIT 20
"""

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


@functions_framework.http
def app(request):
    if request.method == "OPTIONS":
        return ("", 204, CORS_HEADERS)
    try:
        rows = bq.query(SQL).result()
        data = [{"KANRI_DATE": r.KANRI_DATE, "SUMMARY": r.SUMMARY} for r in rows]
        return (jsonify(data), 200, CORS_HEADERS)
    except Exception as e:
        return (jsonify({"error": str(e)}), 500, CORS_HEADERS)
