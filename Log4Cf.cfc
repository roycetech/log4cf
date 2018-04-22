/**
 * Simple logger. Configuration via yml file or via runtime. Will look for
 * log4cf.yml in root classes directory.
 *
 * Example log4cf.yml. Copy this to project root folder
 */
component Log4Cf accessors=true {

    property Numeric defaultLevel;
    property Boolean showMethod;

    /**
     * This will be the subject of the logger. Set this using getInstance(Class)
     * otherwise the calling class will be the active Class.
     */
    property String activeClass;

    /**
     * Flag to enable/disable class name or simple name.
     */
    property String showPackage;

    /**
     * Flag to enable/disable shortened (remove '<appname>.' prefix)
     * package.
     */
    property String shortPackage;


    /** Level - Message separator. */
    SEP_MSG = " - ";


    /** Log levels. */
    Level = {
        /** Will never show. */
        OFF = 6,
        /** Most detailed. */
        IGNORE = 1,
        /** Verbose. */
        DEBUG = 2,
        /** */
        INFO = 3,
        /** Important, appears in red. */
        WARN = 4,
        /** Critical, appears in red. */
        ERROR = 5
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
        "IGNO",
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
        // setDefaultLevel(Level.INFO);
        setShowMethod(True);
        setShowPackage(True);
        setShortPackage(True);

        /**
         * Flag to determine if running on local JDeveloper or E-Business Suite
         * instance..
         */
        variables.classLevel = {};
        application.ignoreList = "";

        if (!structKeyExists(application, "LOG4CF_INITIALIZED")) {

            var config = loadYaml('log4cf');
            initConfig(config);



            application.LOG4CF_INITIALIZED = True;
        }

        setActiveClass('');
        return this;
    }

    private Void function initConfig(required Struct config)
    {
            // try {
            //     required ResourceBundle resBundle =
            //             ResourceBundle.getBundle(RESOURCE_NAME);

            //     required String cfgDefaultLevel =
            //             resBundle.getString("log4cf.defaultLevel");



            //     required Map<String, Integer> levelToStr =
            //             new HashMap<String, Integer>();
            //     levelToStr.put("INFO", Level.INFO);
            //     levelToStr.put("DEBUG", Level.DEBUG);
            //     levelToStr.put("WARN", Level.WARN);
            //     levelToStr.put("ERROR", Level.ERROR);
            //     levelToStr.put("OFF", Level.OFF);

            //     setDefaultLevel();
            //     INSTANCE.defaultLevel =
            //             nvl(
            //                 levelToStr.get(cfgDefaultLevel),
            //                 Level.INFO);

            //     INSTANCE.showMethod =
            //             getResourceValue(
            //                 resBundle,
            //                 "log4cf.showMethod",
            //                 INSTANCE.showMethod);
            //     INSTANCE.showPackage =
            //             getResourceValue(
            //                 resBundle,
            //                 "log4cf.showPackage",
            //                 INSTANCE.showPackage);
            //     INSTANCE.shortPackage =
            //             getResourceValue(
            //                 resBundle,
            //                 "log4cf.shortPackage",
            //                 INSTANCE.shortPackage);
            //     INSTANCE.basePackage = resBundle.getString("log4cf.basepkg");
            //     INSTANCE.printToConsole =
            //             getResourceValue(
            //                 resBundle,
            //                 "log4cf.printToConsole",
            //                 INSTANCE.printToConsole);
            //     INSTANCE.deployed =
            //             getResourceValue(
            //                 resBundle,
            //                 "log4cf.isDeployed",
            //                 INSTANCE.deployed);

            //     for (required Enumeration<String> enu = resBundle.getKeys(); enu
            //         .hasMoreElements();) {
            //         required String logger = enu.nextElement();
            //         if (logger.startsWith("log4cf.logger.")
            //                 && !"log4cf.logger.".equals(logger.trim())) {
            //             required String classPrefix = logger.substring(15);
            //             INSTANCE.setLevel(
            //                 classPrefix,
            //                 levelToStr.get(resBundle.getString(logger).trim()));
            //         }
            //     }

            //     INSTANCE.print(INSTANCE.getClass().getSimpleName() +  ": Completed configuring from " + RESOURCE_NAME
            //             + ".properties", OafLogger.Level.INFO);
            // } catch (any error) {
            //     writeLog("Error loading configuration file: #RESOURCE_NAME#.yml");
            //     writeLog("You can still log by configuring from client calls.");
            // }
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

        var jarPath = expandPath("../lib/jyaml-1.3.jar");
        javaLoader = javaloaderComponent.init(
            [jarPath]);

        // Create jyml class
        var yaml = javaloader.create("org.ho.yaml.Yaml");

        writeDump(expandPath("../log4cf.yml"));


        var dataFile = createObject("java", "java.io.File").init(
            expandPath("../log4cf.yml")
        );

        return yaml.load(dataFile);
    }

    // /**
    //  * Retrieve key values from resource.
    //  *
    //  * @param resBundle resource bundle.
    //  * @param resourceKey resource key.
    //  * @param defaultValue default value to use if resource key do not exist.
    //  */
    // private function Boolean getResourceValue(required ResourceBundle resBundle,
    //                                         required String resourceKey,
    //                                         required boolean defaultValue)
    // {
    //     boolean retval; //NOPMD: false default, conditionally redefine.
    //     try {
    //         String resValue;
    //         if (resBundle.getString(resourceKey) == null) {
    //             resValue = "false";
    //         } else {
    //             resValue = resBundle.getString(resourceKey).trim();
    //         }

    //         retval =
    //                 Arrays.asList(new String[] { //NOPMD: FP.
    //                             "yes",
    //                             "true" }).contains(
    //                     resValue.toLowerCase(Locale.getDefault()));
    //     } catch (required MissingResourceException mre) { //NOPMD Reviewed.
    //         retval = defaultValue;
    //     }
    //     return retval;
    // }

    /**
     * @param source source class.
     * @param level log level.
     *
     * @param <T> source class type.
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

    // public void function debug(required OAPageContext pageContext, required Object message)
    // {
    //     required StackTraceElement ste =
    //             Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
    //                     : IDX_LOCAL_CALL];
    //     if (pageContext == null) {
    //         log(message, ste, Level.DEBUG);
    //     } else {
    //         log(pageContext, message, ste, Level.DEBUG);
    //     }
    // }

    // public void function warn(required OAPageContext pageContext, required Object message)
    // {
    //     required StackTraceElement ste =
    //             Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
    //                     : IDX_LOCAL_CALL];
    //     if (pageContext == null) {
    //         log(message, ste, Level.WARN);
    //     } else {
    //         log(pageContext, message, ste, Level.WARN);
    //     }
    // }

    // public void function error(required OAPageContext pageContext, required Object message)
    // {
    //     required StackTraceElement ste =
    //             Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
    //                     : IDX_LOCAL_CALL];
    //     log(pageContext, message, ste, Level.ERROR);
    // }

    // /**
    //  * For controller code or object with access to page context.
    //  *
    //  * @param pageContext the current OA page context.
    //  * @param message
    //  */
    // public void function log(required OAPageContext pageContext, required Object message)
    // {
    //     var ste =
    //             Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
    //                     : IDX_LOCAL_CALL];
    //     _log(message, ste, this.defaultLevel);
    // }

    private Void function _log(
            required String text,
            required Struct ste,
            required Numeric level,
            String bucket="default")
    {
        if (!isPrintToConsole() || !isPrinted(
                getClassName(arguments.ste),
                arguments.level,
                arguments.bucket)) {
            return;
        }

        var className = getClassNameDisp(ste);
        var methName = getMethodDisp(ste);
        var lineNo = ste.getLineNumber();

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
        if (!isNull(arguments.className) &&
            !isInIgnoreList(arguments.className)) {
                return isUnIgnoredPrinted(retval, className, level);
        }
        return true;
    }

    /**
     * @hint refactored from #isPrinted().
     */
    private Boolean function isClassLevelPrinted(
        required boolean currentVal,
        required String className,
        required Numeric level)
    {
        var retval = arguments.currentVal;
        var isIdentified = false;
        for (var classLevel in variables.classLevel) {
            if (className.startsWith(classLevel)) {
                retval =
                        level >= this.classLevel.get(classLevel)
                                && this.classLevel.get(nextClsLvl) != Level.OFF;
                isIdentified = true;
            }
        }
        if (!isIdentified) {
            return level >= this.defaultLevel;
        }
        return retval;
    }

    /**
     * @className cf dotted component name.
     */
    boolean function isInIgnoreList(required String className)
    {
        for (var nextIgnore in this.ignoreSet) {
            if (className.startsWith(nextIgnore)) {
                return true;
            }
        }
        return false;
    }

    String function getMethodDisp(required String stackTraceElement)
    {
        return getShowMethod() ? '##' & argements.stackTraceElement.function : "";
    }

    /**
     * @ste stack trace element.
     */
    private String function getClassNameDisp(required Struct ste)
    {
        var className = ('' == getActiveClass() ? getClassName(arguments.ste) : getActiveClass());
        var retval = '';
        if (getShowPackage()) {
            retval = className;
            if (getShortPackage()) {
                retval = className.substring(INSTANCE.basePackage.length());
            }
        } else {
            retval = className.substring(className.lastIndexOf('.') + 1);
        }
        return retval;
    }

    /**
     * Returns the template name.
     */
    private String function getClassName(required Struct ste)
    {
        return '' == getActiveClass() ? ste.template : getActiveClass();
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
            text="#timeStamp# [##] #arguments.message#");
    }

    // =Reviewed =============================================================

    private String function padSpaceByLevel(required String level)
    {
        var retval = '';
        if (!isNull(level)) {
            retval = level;
            switch (len(arguments.level)) {
                case 4:
                    retval &= " ";
                case 3:
                    retval &= "  ";
            }
        }
        return retval;
    }


    private String function padSpaceByCount(required Numeric count)
    {
        var retval = '';
        for (var i = 0; i < arguments.count; i++) {
            retval &= ' ';
        }
        return retval;
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
     * Global flag to check if logging is enabled.
     */
    private Boolean function isEnabled()
    {
        return structKeyExists(application, 'LOG4CF_ENABLED');
    }

    /**
     * @callStack the call stack.
     */
    private String function calcRelativePath(required Struct callStack)
    {
        return replace(arguments.callStack.template, variables.baseProject, "");
    }
}

