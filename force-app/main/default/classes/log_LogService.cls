@SuppressWarnings('PMD.ClassNamingConventions, PMD.ExcessiveParameterList, PMD.FieldNamingConventions')
public virtual class log_LogService {
    public static String RECORD_TYPE = 'Standard';
    public static String CORRELATION_ID = getGUID();

    @TestVisible
    private static final List<log_Log_Event__e> LOG_EVENTS = new List<log_Log_Event__e>();

    @TestVisible
    private static final Integer MAX_MSG_SIZE = 131072;

    @TestVisible
    private static final String MAX_SIZE_MSG = '.MAX LENGTH IS EXCEEDED...';

    public void setRecordType(String recordTypeApiName) {
        RECORD_TYPE = recordTypeApiName;
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param obj required, Object to serialize into the Log message
     */
    public static void log(String name, LogType logType, Object obj) {
        log(name, logType, RECORD_TYPE, obj);
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param recordType required, Log record RecordType Name
     * @param obj required, Object to serialize into the Log message
     * */
    public static void log(String name, LogType logType, String recordType, Object obj) {
        if (obj != null) {
            log(name, logType, recordType, JSON.serializePretty(obj));
        }
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param objs required, List<Object> to serialize into the Log message
     * */
    public static void log(String name, LogType logType, List<Object> objs) {
        log(name, logType, RECORD_TYPE, objs);
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param recordType required, Log record RecordType Name
     * @param objs required, List<Object> to serialize into the Log message
     * */
    public static void log(String name, LogType logType, String recordType, List<Object> objs) {
        if (objs != null) {
            log(name, logType, recordType, JSON.serializePretty(objs));
        }
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param objs required, List<Object> to serialize into the Log message
     * @param correlationId, optional, String with max length 36 characters
     * */
    public static void log(String name, LogType logType, List<Object> objs, String correlationId) {
        log(name, logType, RECORD_TYPE, objs, correlationId);
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param recordType required, Log record RecordType Name
     * @param objs required, List<Object> to serialize into the Log message
     * @param correlationId, optional, String with max length 36 characters
     * */
    public static void log(String name, LogType logType, String recordType, List<Object> objs, String correlationId) {
        if (objs == null) {
            return;
        }
        if (String.isNotBlank(correlationId)) {
            CORRELATION_ID = correlationId;
        }
        for (Object obj : objs) {
            if (obj != null) {
                log(name, logType, recordType, JSON.serializePretty(obj));
            }
        }
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param ex required, Exception record to serialize into the Log message
     * */
    public static void log(String name, LogType logType, Exception ex) {
        log(name, logType, RECORD_TYPE, ex);
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param recordType required, Log record RecordType Name
     * @param ex required, Exception record to serialize into the Log message
     * */
    public static void log(String name, LogType logType, String recordType, Exception ex) {
        if (ex != null) {
            log(name, logType, recordType, ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param ex required, Exception record to serialize into the Log message
     * @param correlationId, optional, String with max length 36 characters
     * */
    public static void log(String name, LogType logType, Exception ex, String correlationId) {
        log(name, logType, RECORD_TYPE, ex, correlationId);
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param recordType required, Log record RecordType Name
     * @param ex required, Exception record to serialize into the Log message
     * @param correlationId, optional, String with max length 36 characters
     * */
    public static void log(String name, LogType logType, String recordType, Exception ex, String correlationId) {
        if (ex == null) {
            return;
        }
        if (String.isNotBlank(correlationId)) {
            CORRELATION_ID = correlationId;
        }
        log(name, logType, recordType, ex.getMessage() + '\n' + ex.getStackTraceString());
    }

    public static void log(String name, LogType logType, String message) {
        log(name, logType, message, RECORD_TYPE, CORRELATION_ID);
    }

    public static void log(String name, LogType logType, String message, String correlationId) {
        log(name, logType, message, RECORD_TYPE, correlationId);
    }

    /**
     * @param name required, String with max length 80 characters
     * @param logType required, LogType enum value
     * @param recordType required, Log record RecordType Name
     * @param message required, String with max length 131072 characters, bigger messages are cut off to fit the field size
     * @param correlationId, optional, String with max length 36 characters
     * */
    public static void log(String name, LogType logType, String message, String recordType, String correlationId) {
        if (String.isNotBlank(correlationId)) {
            CORRELATION_ID = correlationId;
        }
        LOG_EVENTS.add(
            new log_Log_Event__e(
                Log_Name__c = name,
                Timestamp__c = Datetime.now(),
                Correlation_Id__c = CORRELATION_ID,
                Log_Type__c = logType.name(),
                Username__c = UserInfo.getUserName(),
                Message__c = message,
                Record_Type_Name__c = recordType
            )
        );
        System.debug(LoggingLevel.INFO, JSON.serializePretty(LOG_EVENTS[LOG_EVENTS.size() - 1]));
    }

    public static void publish() {
        try {
            EventBus.publish(LOG_EVENTS);
            LOG_EVENTS.clear();
        } catch (Exception e) {
            System.debug(LoggingLevel.INFO, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    /**
     * @param logEvents List<log_Event__e> list of Log Event records which are used to create Log records
     *  */
    public static void insertLogs(List<log_Log_Event__e> logEvents) {
        if (logEvents == null) {
            return;
        }
        fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{ log_Log__c.SObjectType });
        Map<String, RecordTypeInfo> recordTypes = Schema.SObjectType.log_Log__c.getRecordTypeInfosByName();
        List<log_Log__c> logs = new List<log_Log__c>();
        for (log_Log_Event__e logEvent : logEvents) {
            logs.add(
                new log_Log__c(
                    Name = logEvent.Log_Name__c,
                    Timestamp__c = logEvent.Timestamp__c,
                    Correlation_Id__c = logEvent.Correlation_Id__c,
                    Log_Type__c = logEvent.Log_Type__c,
                    Username__c = logEvent.Username__c,
                    Message__c = logEvent.Message__c,
                    RecordTypeId = recordTypes.containsKey(logEvent.Record_Type_Name__c) ? recordTypes.get(logEvent.Record_Type_Name__c).getRecordTypeId() : null
                )
            );
        }
        log_LogService.insertLogs(logs, uow);
        uow.commitWork();
    }

    /**
     * @param logs List<log_Log__c> list of Log records to insert
     * @param uow fflib_ISObjectUnitOfWork unit of work
     * */
    public static void insertLogs(List<log_Log__c> logs, fflib_ISObjectUnitOfWork uow) {
        uow.registerNew(logs);
    }

    /**
     * @param logs List<log_Log__c> list of Log records to insert
     *  */
    public static void deleteLogs(List<log_Log__c> logs) {
        fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{ log_Log__c.SObjectType });
        log_LogService.deleteLogs(logs, uow);
        uow.commitWork();
    }

    /**
     * @param logs List<log_Log__c> list of Log records to delete
     * @param uow fflib_ISObjectUnitOfWork unit of work
     * */
    public static void deleteLogs(List<log_Log__c> logs, fflib_ISObjectUnitOfWork uow) {
        uow.registerDeleted(logs);
    }

    /**
     * @param message String, Log record message
     *  */
    @TestVisible
    private static String messageCheck(String message) {
        if (message != null && message.length() > MAX_MSG_SIZE) {
            return message.substring(0, (MAX_MSG_SIZE - MAX_SIZE_MSG.length())) + MAX_SIZE_MSG;
        }
        return message;
    }

    private static String getGUID() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0, 8) + '-' + h.substring(8, 12) + '-' + h.substring(12, 16) + '-' + h.substring(16, 20) + '-' + h.substring(20);
    }

    public enum LogType {
        ERROR,
        INFO
    }
}