/**
 * Simple logger. Configuration via yml file or via runtime. Will look for
 * log4cf.yml in root classes directory.
 *
 * Example log4cf.yml. Copy this to project root folder
 */
component Log4Cf accessors=true {

    property Numeric defaultLevel;
    property Boolean showFunction;

    /**
     * This will be the subject of the logger. Set this using getInstance(Class)
     * otherwise the calling class will be the active Class.
     */
    property String activeClass;

    /**
     * Flag to enable/disable class name or simple name.
     */
    property String showPackage;


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

    /** */
    LOG_PREFIX = [
        "DEBUG",
        "INFO",
        "WARN",
        "ERROR"
    ];

    /**
     * Constructor.
     */
    Log4Cf function init()
    {
        variables.classLevel = {};
        application.ignoreList = "";

        if (!structKeyExists(application, "LOG4CF_INITIALIZED")) {
            variables.config = loadYaml(RESOURCE_NAME)['log4cf'];
            initConfig();

            application['LOG4CF_INITIALIZED'] = true;
            writeDump(structKeyExists(application, "LOG4CF_INITIALIZED"));
        }

        setActiveClass('');
        return this;
    }

    private Void function initConfig()
    {
        writeDump(variables.config);
        variables.serverPath = config['cf_web_root'];

        setDefaultLevel(Level[readConfig('default_level', Level.INFO)]);
        setShowFunction(readConfig('show_function', false));
        setShowPackage(readConfig('show_package', true));

        structEach(variables.config['categories'], function(key, value) {
            var calcKey = replace(key, '.', '/', 'all');
            variables.classLevel[calcKey] = value;
        });

        writeDump(variables.classLevel);

            //     INSTANCE.print(INSTANCE.getClass().getSimpleName() +  ": Completed configuring from " + RESOURCE_NAME
            //             + ".properties", OafLogger.Level.INFO);
            // } catch (any error) {
            //     writeLog("Error loading configuration file: #RESOURCE_NAME#.yml");
            //     writeLog("You can still log by configuring from client calls.");
            // }
    }

    private String function readConfig(
            required String key,
            required String defaultValue)
    {
        return nvl(
            variables.config[arguments.key],
            arguments.defaultValue
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
            expandPath("/log4cf/log4cf.yml")
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

    Void function info(String text='', String bucket="default")
    {

        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.INFO, arguments.bucket);
    }

    public void function debug(String text='', String bucket="default")
    {
        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.DEBUG, arguments.bucket);
    }

    public void function warn(String text='', String bucket="default")
    {
        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.WARN, arguments.bucket);
    }

    public void function error(String text='', String bucket="default")
    {
        var callStack = callStackGet()[2];
        _log(arguments.text, callStack, Level.ERROR, arguments.bucket);
    }

    private Void function _log(
            required String text,
            required Struct ste,
            required Numeric level,
            String bucket="default")
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
             arguments.level
        );
    }

    /** Checks the className against the ignore Set; */
    private Boolean function isPrinted(
            required String className,
            required Numeric level)
    {
        if (!isNull(arguments.className)) {
            return isClassLevelPrinted(arguments.className, arguments.level);
        }
        return true;
    }

    /**
     * @hint refactored from #isPrinted().
     * @logLevel the target log level or the method used to log.
     */
    private Boolean function isClassLevelPrinted(
        required String className,
        required Numeric loglevel)
    {
        var retval = false;
        var isIdentified = false;
        for (var classLevel in variables.classLevel) {

            // writeLog("CClassName: #classLevel#, className: #className#, CLevel: #variables.classLevel.get(classLevel)#, Level: #arguments.logLevel#");


            if (left(className, len(classLevel)) == classLevel) {
                retval =
                        arguments.logLevel >= Level[variables.classLevel.get(classLevel)]
                                && variables.classLevel.get(classLevel) != Level.OFF;
                isIdentified = true;
            }
        }
        if (!isIdentified) {
            return logLevel >= getDefaultLevel();
        }

        // writeLog(retval);

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
        var className = ('' == getActiveClass() ? getClassName(arguments.ste) : getActiveClass());
        if (getShowPackage()) {
            return className;
        }
        return right(className, len(className) - find('/', className));
    }

    /**
     * Returns the template name.
     */
    private String function getClassName(required Struct ste)
    {
        return replace(ste.template, variables.serverPath, '');
    }

    private Void function print(
            required String message,
            required Numeric level,
            required String bucket="default")
    {
        var timeStamp = dateTimeFormat(now(), "yyyy/mm/dd HH:nn:ss");
        writeLog(
            type=LevelToType[arguments.level],
            file=arguments.bucket,
            text="[#LOG_PREFIX[level]#] #arguments.message#");
    }

    /**
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

