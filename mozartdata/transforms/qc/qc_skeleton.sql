SELECT LISTAGG(
    'SELECT
      ''' || COLUMN_NAME || ''' AS ColumnName,
      ''' || DATA_TYPE || ''' AS Datatype,
      COUNT(*) AS TotalRows,
      SUM(CASE WHEN ' || COLUMN_NAME || ' IS NULL THEN 1 ELSE 0 END) AS NullCount,
      COUNT(*) - COUNT(DISTINCT ' || COLUMN_NAME || ') AS DuplicateCount,
      TO_VARCHAR(MIN('||COLUMN_NAME||')) As MinValue,
      TO_VARCHAR(MAX('||COLUMN_NAME||')) As MaxValue
    FROM ' || 'DIM.KLAVIYO_CAMPAIGNS',
    ' UNION ALL '
  ) WITHIN GROUP (ORDER BY COLUMN_NAME)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'DIM' AND TABLE_NAME = 'KLAVIYO_CAMPAIGNS'