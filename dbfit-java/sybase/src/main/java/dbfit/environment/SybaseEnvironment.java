package dbfit.environment;

import dbfit.annotations.DatabaseEnvironment;
import dbfit.api.AbstractDbEnvironment;
import dbfit.util.DbParameterAccessor;
import dbfit.util.DbParameterAccessorsMapBuilder;
import dbfit.util.Direction;
import static dbfit.util.Direction.*;
import static dbfit.util.NameNormaliser.normaliseName;
import dbfit.util.TypeNormaliserFactory;
import static dbfit.environment.SybaseTypeNameNormaliser.normaliseTypeName;


import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;

import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.Properties;

import static org.apache.commons.lang3.ObjectUtils.defaultIfNull;

@DatabaseEnvironment(name="Sybase", driver="net.sourceforge.jtds.jdbc.Driver")
public class SybaseEnvironment extends AbstractDbEnvironment {

    public SybaseEnvironment(String driverClassName) {
        super(driverClassName);

        TypeNormaliserFactory.setNormaliser(java.sql.Time.class,
                new MillisecondTimeNormaliser());
    }

    public boolean supportsOuputOnInsert() {
        return false;
    }

    @Override
    protected String getConnectionString(String dataSource) {
        return "jdbc:jtds:sybase://" + dataSource;
    }

    @Override
    protected String getConnectionString(String dataSource, String database) {
        return getConnectionString(dataSource) + ";database=" + database;
    }

    @Override
    public void connect(String connectionString, Properties info) throws SQLException {
        // Add sendTimeAsDatetime=false option to enforce sending Time as
        // java.sql.Time (otherwise some precision is lost in conversions)
        super.connect(connectionString + ";sendTimeAsDatetime=false", info);
        /*SybDriver sybDriver = null;
**
**        try{
**                sybDriver = (SybDriver)Class.forName("com.sybase.jdbc2.jdbc.SybDriver").newInstance();
**                currentConnection = DriverManager.getConnection(connectionString, info.getProperty("user"),info.getProperty("password"));
**        }catch(Exception E){
**               E.printStackTrace();
**           */
    }

    private static String paramNamePattern = "@([A-Za-z0-9_]+)";
    private static Pattern paramRegex = Pattern.compile(paramNamePattern);

    public Pattern getParameterPattern() {
        return paramRegex;
    }

    protected String parseCommandText(String commandText) {
        commandText = commandText.replaceAll(paramNamePattern, "?");
        return super.parseCommandText(commandText);
    }

    public Map<String, DbParameterAccessor> getAllColumns(String tableOrViewName)
            throws SQLException {
//        String qry = " select c.[name], TYPE_NAME(c.system_type_id) as [Type], c.max_length, "
//                + " 0 As is_output, 0 As is_cursor_ref "
//                + " from syscolumns c "
//                + " where c.object_id = OBJECT_ID(?) "
//                + " order by column_id";
          String qry = " select c.[name], "
                      +"       CONVERT (char(30), SUBSTRING (T2.name, 1, CHAR_LENGTH (RTRIM (T2.name)) - "
                      +"             CHARINDEX ('n', SUBSTRING (T2.name, CHAR_LENGTH (RTRIM (T2.name)), 1)))) as [Type], "
                      +"       c.length, 0 As is_output, 0 As is_cursor_ref "
                      +" from syscolumns c , systypes T1, systypes T2 "
                      +" where c.id = OBJECT_ID(?) "
                      +"  and   T1.usertype  = c.usertype "
                      +"  and   T2.type      = T1.type "
                      +"  and   T2.name     IN ('char', 'int', 'intn', 'bigint','bigintn', "
                      +"                        'datetime', 'float', 'floatn', 'varchar', 'smallint', 'tinyint') "
                      +" order by colid ";
        return readIntoParams(tableOrViewName, qry);
    }

    private Map<String, DbParameterAccessor> readIntoParams(String objname,
            String query) throws SQLException {
        DbParameterAccessorsMapBuilder params = new DbParameterAccessorsMapBuilder(dbfitToJdbcTransformerFactory);

        if (objname.contains(".")) {
            String[] schemaAndName = objname.split("[\\.]", 2);
            objname = "[" + schemaAndName[0] + "].[" + schemaAndName[1] + "]";
        } else {
            objname = "[" + normaliseName(objname) + "]";
        }

        try (PreparedStatement dc = currentConnection.prepareStatement(query)) {
            dc.setString(1, normaliseName(objname));
            ResultSet rs = dc.executeQuery();

            while (rs.next()) {
                String paramName = defaultIfNull(rs.getString(1), "");
                params.add(paramName,
                           getParameterDirection(rs.getInt(4), paramName),
                           getSqlType(rs.getString(2)),
                           getJavaClass(rs.getString(2)));
            }
        }

        return params.toMap();
    }

    // List interface has sequential search, so using list instead of array to
    // map types
    private static List<String> stringTypes = Arrays.asList(new String[] {
            "VARCHAR", "NVARCHAR", "CHAR", "NCHAR", "TEXT", "NTEXT",
            "UNIQUEIDENTIFIER" });
    private static List<String> intTypes = Arrays
            .asList(new String[] { "INT" });
    private static List<String> booleanTypes = Arrays
            .asList(new String[] { "BIT" });
    private static List<String> floatTypes = Arrays
            .asList(new String[] { "REAL" });
    private static List<String> doubleTypes = Arrays
            .asList(new String[] { "FLOAT" });
    private static List<String> longTypes = Arrays
            .asList(new String[] { "BIGINT" });
    private static List<String> shortTypes = Arrays.asList(new String[] {
            "TINYINT", "SMALLINT" });

    private static List<String> numericTypes = Arrays.asList("NUMERIC");
    private static List<String> decimalTypes = Arrays.asList(new String[] {
            "DECIMAL", "MONEY", "SMALLMONEY" });
    private static List<String> timestampTypes = Arrays.asList(new String[] {
            "SMALLDATETIME", "DATETIME", "DATETIME2", "TIMESTAMP" });
    private static List<String> dateTypes = Arrays.asList("DATE");
    private static List<String> timeTypes = Arrays.asList("TIME");

    // private static List<String> refCursorTypes = Arrays.asList(new String[] {
    // });
    // private static List<String> doubleTypes=Arrays.asList(new
    // String[]{"DOUBLE"});

    // private static string[] BinaryTypes=new string[] {"BINARY","VARBINARY"};
    // private static string[] GuidTypes = new string[] { "UNIQUEIDENTIFIER" };
    // private static string[] VariantTypes = new string[] { "SQL_VARIANT" };

    private static Direction getParameterDirection(int isOutput, String name) {
        if (name.isEmpty()) {
            return RETURN_VALUE;
        }

        return (isOutput == 1) ? OUTPUT : INPUT;
    }

    private static int getSqlType(String dataType) {
        // todo:strip everything from first blank
        dataType = normaliseTypeName(dataType);

        if (stringTypes.contains(dataType))
            return java.sql.Types.VARCHAR;
        if (numericTypes.contains(dataType))
            return java.sql.Types.NUMERIC;
        if (decimalTypes.contains(dataType))
            return java.sql.Types.DECIMAL;
        if (intTypes.contains(dataType))
            return java.sql.Types.INTEGER;
        if (timestampTypes.contains(dataType))
            return java.sql.Types.TIMESTAMP;
        if (dateTypes.contains(dataType))
            return java.sql.Types.DATE;
        if (timeTypes.contains(dataType))
            return java.sql.Types.TIME;
        if (booleanTypes.contains(dataType))
            return java.sql.Types.BOOLEAN;
        if (floatTypes.contains(dataType))
            return java.sql.Types.FLOAT;
        if (doubleTypes.contains(dataType))
            return java.sql.Types.DOUBLE;

        if (longTypes.contains(dataType))
            return java.sql.Types.BIGINT;
        if (shortTypes.contains(dataType))
            return java.sql.Types.SMALLINT;

        throw new UnsupportedOperationException("Type " + dataType
                + " is not supported");
    }

    public Class<?> getJavaClass(String dataType) {
        dataType = normaliseTypeName(dataType);
        if (stringTypes.contains(dataType))
            return String.class;
        if (numericTypes.contains(dataType))
            return BigDecimal.class;
        if (decimalTypes.contains(dataType))
            return BigDecimal.class;
        if (intTypes.contains(dataType))
            return Integer.class;
        if (timestampTypes.contains(dataType))
            return java.sql.Timestamp.class;
        if (dateTypes.contains(dataType))
            return java.sql.Date.class;
        if (timeTypes.contains(dataType))
            return java.sql.Time.class;
        if (booleanTypes.contains(dataType))
            return Boolean.class;
        if (floatTypes.contains(dataType))
            return Float.class;
        if (doubleTypes.contains(dataType))
            return Double.class;
        if (longTypes.contains(dataType))
            return Long.class;
        if (shortTypes.contains(dataType))
            return Short.class;

        throw new UnsupportedOperationException("Type " + dataType
                + " is not supported");
    }

    public Map<String, DbParameterAccessor> getAllProcedureParameters(
            String procName) throws SQLException {
        return readIntoParams(
                procName,
//                "select p.[name], TYPE_NAME(p.system_type_id) as [Type],  "
//                        + " p.max_length, p.is_output, p.is_cursor_ref from sys.parameters p "
//                        + " where p.object_id = OBJECT_ID(?) order by parameter_id ");

                "select p.[name], "
               +"       CONVERT (char(30), SUBSTRING (T2.name, 1, CHAR_LENGTH (RTRIM (T2.name)) - "
               +"         CHARINDEX ('n', SUBSTRING (T2.name, CHAR_LENGTH (RTRIM (T2.name)), 1)))) as [Type],  "
               +"       max_length = p.length, "
               +"       case status2 when 2 then 1 else 0 end as [is_output] , "
               +"       is_cursor_ref = 0               "
               +"from syscolumns p , systypes T1, systypes T2 "
               +"where p.id = OBJECT_ID(?) "
               +"  and   T1.usertype  = p.usertype "
               +"  and   T2.type      = T1.type "
               +"  and   T2.name     IN ('char', 'int', 'intn', 'bigint','bigintn', "
               +"                        'datetime', 'float', 'floatn', 'varchar', 'smallint', 'tinyint') "
               +"order by colid ");

    }

    public String buildInsertCommand(String tableName,
            DbParameterAccessor[] accessors) {
        StringBuilder sb = new StringBuilder("insert into ");
        sb.append(tableName).append("(");
        String comma = "";

        StringBuilder values = new StringBuilder();

        for (DbParameterAccessor accessor : accessors) {
            if (accessor.hasDirection(Direction.INPUT)) {
                sb.append(comma);
                values.append(comma);
                //This will allow column names that have spaces or are keywords.
                sb.append("[" + accessor.getName() + "]");
                values.append("?");
                comma = ",";
            }
        }
        sb.append(") values (");
        sb.append(values);
        sb.append(")");
        return sb.toString();
    }
}

