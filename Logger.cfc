/**
 * Simple logger. Configuration via yml file or via runtime. Will look for
 * log4cf.yml in root classes directory.
 *
 * Example log4cf.yml. Copy this to project root folder
 * TODO:
 *
 * Remove active class.
 */
component Logger accessors=true {

    property Numeric defaultLevel;
    property Boolean showFunction;

    /**
     * Flag to enable/disable class name or simple name.
     */
    property String showPackage;
    property Boolean useDump;


    /** Level - Message separator. */
    SEP_MSG = " - ";


    /** Log levels. */
    Level = {
        /** Will never show. */
        OFF = 5,
        /** Verbose. */
        DEBUG = 1,
        /** */
        INFO = 2,
        /** Important, appears in red. */
        WARN = 3,
        /** Critical, appears in red. */
        ERROR = 4
    };

    LevelToType = {
        "#Level.INFO#" = "Information",
        "#Level.DEBUG#" = "Information",
        "#Level.WARN#" = "Warning",
        "#Level.ERROR#" = "Error"
    };

    /** Logging yml config file. */
    RESOURCE_NAME = "log4cf";

    DEFAULT_BUCKET = "default";

    /** */
    LOG_PREFIX = [
        "DEBUG",
        "INFO",
        "WARN",
        "ERROR"
    ];

    /**
     * Constructor.
     * @bucket the default bucket to use for this logger instance.
     *
     */
    Logger function init(String bucket=DEFAULT_BUCKET)
    {
        variables.categoryLevelMapping = {};
        initCallingApp();

        if ((!structKeyExists(application, "LOG4CF_INITIALIZED")
                || structKeyExists(application, "LOG4CF_ALWAYS_RELOAD")
                && application.LOG4CF_ALWAYS_RELOAD)
                && !structKeyExists(request, "LOG4CF_INITIALIZED")) {

            application.config = loadYaml(RESOURCE_NAME)['log4cf'];
            application.LOG4CF_INITIALIZED = true;
            request.LOG4CF_INITIALIZED = true;
            writeLog("Initialized log4cf.");
        }

        variables.config = application.config;

        /**
         * List of cgi attributes you may want to include in the log.
         */
        variables.cgi = '';

        initConfig();
        variables.bucket = arguments.bucket;

        return this;
    }

    private Void function initConfig()
    {
        setDefaultLevel(Level[readConfig('default_level', Level.INFO)]);
        setShowFunction(readConfig('show_function', false));
        setShowPackage(readConfig('show_package', true));
        setUseDump(readConfig('use_dump', false));
        application.LOG4CF_ALWAYS_RELOAD = readConfig('always_reload', false);

        structEach(variables.config['categories'], function(key, value) {
            var calcKey = replace(key, '.', '/', 'all');
            variables.categoryLevelMapping[calcKey] = value;
        });

        structEach(variables.config['buckets'], function(key, value) {
            variables.bucketSwitch[key] = value;
        });

        if (structKeyExists(variables.config, 'cgi')) {
            arrayEach(variables.config['cgi'], function(element) {
                variables.cgi = listAppend(variables.cgi, arguments.element);
            });
        }
    }

    /**
     * Read a configuration item.
     * @key the configuration key.
     * @defaultValue the default value if the key is not found or empty.
     */
    private String function readConfig(
            required String key,
            required String defaultValue)
    {
        return nvl(
            variables.config[arguments.key],
            arguments.defaultValue
        );
    }

    private Void function initCallingApp() {
        var stackTrace = callStackGet();

        variables.serverWebRoot = reReplaceNoCase(
            stackTrace[1].template,
            '(\/\w+\/\w+\.\w+)$',
            ''
        );

        for (var element in stackTrace) {
            if (reFind('/log4cf/', element.template) == 0) {
                initWithStackTrace(element);
                return;
            }
        }
        initWithStackTrace(stackTrace[1]);
    }

    /**
     * Initialize the app name with the given stack trace element.
     */
    private Void function initWithStackTrace(required Struct ste)
    {
            var removedWebRoot = replace(
                ste.template,
                variables.serverWebRoot & '/',
                ''
            );
            variables.appName = left(
                removedWebRoot,
                find('/', removedWebRoot) - 1
            );
    }

    /**
     * @yamlName filename without extension. Must be available at the root of the project.
     */
    private Struct function loadYaml(required String yamlName)
    {
        // Load jyml.jar with JavaLoader
        javaloaderComponent = createObject(
            "component",
            "javaloader.JavaLoader"
        );

        var jarPath = expandPath("/log4cf/lib/jyaml-1.3.jar");
        javaLoader = javaloaderComponent.init(
            [jarPath]);

        // Create jyml class
        var yaml = javaloader.create("org.ho.yaml.Yaml");

        var dataFile = createObject("java", "java.io.File").init(
            expandPath("/#variables.appName#/log4cf.yml")
        );

        return yaml.load(dataFile);
    }


    /**
     * @param source source class.
     * @param level log level.
     */
    Void function setLevel(required Component source, required Numeric level)
    {
        if (!isNull(arguments.source) && arguments.level <= Level.ERROR) {
            setLevel(source.getName(), level);
        }
    }

    /* 1. Logger method: OAPagecontext */

    Void function info(String text='', String bucket=variables.bucket)
    {

        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.INFO, arguments.bucket);
    }

    public void function debug(String text='', String bucket=variables.bucket)
    {
        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.DEBUG, arguments.bucket);
    }

    public void function warn(String text='', String bucket=variables.bucket)
    {
        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.WARN, arguments.bucket);
    }

    /**
     * @text error text or the error object itself.
     * @error the error object.
     */
    public void function error(
            any text='',
            any error="",
            String bucket=variables.bucket)
    {
        var errorMsg = '';
        var errorObject = arguments.error;

        if (isInstanceOf(arguments.text, "java.lang.Exception")) {
            errorObject = arguments.text;
            errorMsg = arguments.text.detail;
        } else {
            errorMsg = arguments.text;
        }

        if (isInstanceOf(arguments.error, "java.lang.Exception")) {
            errorMsg &= " - " & arguments.error.detail;
        }

        var callStack = callStackGet()[2];
        _log(errorMsg, callStack, Level.ERROR, arguments.bucket, errorObject);
    }

    private Void function _log(
            required String text,
            required Struct ste,
            required Numeric level,
            required String bucket,
            any errorObject = '')
    {
        if (!isPrinted(
                getClassName(arguments.ste),
                arguments.level,
                arguments.bucket)) {
            return;
        }

        var className = getClassNameDisp(ste);

        var methName = getMethodDisp(ste);
        var lineNo = ste.lineNumber;

        print(
            "#className##methName#:#lineNo##SEP_MSG##arguments.text#",
             arguments.level,
             arguments.bucket
        );

        if (isInstanceOf(arguments.errorObject, "java.lang.Exception")) {
            printStackTrace(arguments.errorObject);
        }
    }

    /** Checks the className against the ignore Set; */
    private Boolean function isPrinted(
            required String className,
            required Numeric level,
            required String bucketName)
    {
        if (!isNull(arguments.className)) {

            return isClassLevelPrinted(arguments.className, arguments.level) &&
                isBucketPrinted(arguments.bucketName);
        }
        return true;
    }

    private Boolean function isBucketPrinted(required String bucketName) {
        return "on" == lcase(variables.bucketSwitch[arguments.bucketName]);
    }

    /**
     * Returns true if string1 starts with string2
     * @string1 rtfc.
     * @string2 rtfc.
     */
    private Boolean function startsWith(
        required String string1,
        required String string2)
    {
        var substringLen = len(arguments.string2);
        return left(arguments.string1, substringLen) == arguments.string2;
    }

    /**
     * @hint refactored from #isPrinted().
     * @logLevel the target log level or the method used to log.
     */
    private Boolean function isClassLevelPrinted(
            required String templateName,
            required Numeric loglevel)
    {
        var retval = false;
        var isIdentified = false;
        for (var category in categoryLevelMapping) {

            if (startsWith(templateName, category)) {

                var categoryLevel = Level[
                    variables.categoryLevelMapping.get(category)
                ];

                var isOn = categoryLevelMapping.get(categoryLevel) != Level.OFF;

                retval = arguments.logLevel >= categoryLevel && isOn;
                isIdentified = true;
            }
        }
        if (!isIdentified) {
            return logLevel >= getDefaultLevel();
        }

        return retval;
    }

    /**
     * @stackTraceElement ste.
     */
    String function getMethodDisp(required Struct stackTraceElement)
    {
        var methodName = lcase(arguments.stackTraceElement.function);
        if (len(methodName) > 0 && getShowFunction()) {
            return "###methodName#";
        }
        return '';
    }

    /**
     * Returns the simple or full component name depending on the configuration.
     * @ste stack trace element.
     */
    private String function getClassNameDisp(required Struct ste)
    {
        var className = getClassName(arguments.ste);
        if (right(className, 3) == 'cfc') {
            className = replace(
                left(className, len(className) - 4),
                '/',
                '.',
                "All"
            );
        }

        if (getShowPackage()) {
            return className;
        }

        var lastIndex = 0;
        if (reFind('\.cfml?', className) > 0) {
            lastIndex = find('/', reverse(className));
        } else {
            lastIndex = find('.', reverse(className));
        }
        return right(className, lastIndex - 1);
   }

    /**
     * Returns the template name.
     */
    private String function getClassName(required Struct ste)
    {
        return replace(
            ste.template,
            variables.serverWebRoot & '/',
            ''
        );
    }

    private Void function print(
            required String message,
            required Numeric level,
            required String bucket)
    {
        var cgiStr = buildCGI();
        if (len(cgiStr) > 0) {
            cgiStr = "CGI[#cgiStr#] ";
        }

        if (getUseDump()) {
            var timeStamp = dateTimeFormat(now(), "yyyy/mm/dd HH:nn:ss tt");
            writeDump(
                var="#timeStamp# #cgiStr#[#padSpaces(LOG_PREFIX[level], 5)#] #arguments.message#",
                output= "console"
            );
        } else {
            writeLog(
                type=LevelToType[arguments.level],
                file="bucket_#arguments.bucket#",
                text=cgiStr & padLeftSpace(
                    "[#padSpaces(LOG_PREFIX[level], 5)#] #arguments.message#",
                    arguments.level
                )
            );
        }
    }

    private String function buildCGI()
    {
        var retval = "";
        for (var element in variables.cgi) {
            retval = listAppend(retval, cgi[element]);
        }
        return retval;
    }

    private Void function printStackTrace(required any errorObject)
    {
        writeDump(
            var=arguments.errorObject.stackTrace,
            output= "console"
        );
    }

    /**
     * @text text to pad with spaces.
     */
    private String function padLeftSpace(
        required String text,
        required Numeric levelParam) {

        var maxLen = len(LevelToType[Level.INFO]);


        var spaces = repeatString(
            ' ',
            maxLen - len(LevelToType[arguments.levelParam])
        );

        return spaces & arguments.text;
    }

    private String function padSpaces(
            required String text,
            required Numeric length,
            String leftOrRight="right")
    {
        var delta = arguments.length - len(arguments.text);
        if (delta < 0) {
            delta = 0;
        }

        var spaces = '';
        for (var i = 1; i <= delta; i++) {
            spaces &= ' ';
        }
        if (arguments.leftOrRight == "right") {
            return arguments.text & spaces;
        }
        return  spaces & arguments.text ;
    }

    // private String function createSpaces(required n)

    /**
     * @value the expression to check if null or empty string.
     * @defaultValue the expression to return if first argument is null or
     * empty.
     * rtfc
     */
    private any function nvl(required any value, any defaultValue)
    {
        if (len(trim(arguments.value)) == 0) {
            return arguments.defaultValue;
        }
        return arguments.value;
    }

    /**
     * @callStack the call stack.
     */
    private String function calcRelativePath(required Struct callStack)
    {
        return replace(arguments.callStack.template, variables.baseProject, '');
    }
}
