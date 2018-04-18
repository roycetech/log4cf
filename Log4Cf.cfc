/**
 * Simple logger. Configuration via yml file or via runtime. Will look for
 * log4cf.yml in root classes directory.
 *
 * Example log4cf.yml. Copy this to project root folder
 *
 * <pre>
 * #log4cf.yml
 *
 * #defaults to INFO
 * log4cf.defaultLevel=INFO
 *
 * #defaults to yes
 * log4cf.showMethod=yes
 *
 * #defaults to yes
 * #log4cf.showPackage=yes
 *
 * #defaults to no
 * log4cf.printToConsole=yes
 *
 * # log categories
 * log4cf.logger.app.utils=DEBUG
 * log4cf.logger.app.utils=INFO
 * log4cf.logger.app.utils=OFF
 *
 * # log packages
 * log4cf.bucket.potato=ON
 * log4cf.bucket.banana=OFF
 * log4cf.bucket.default=ON
 */
component Log4Cf {

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
    }

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
        application.ignoreList = "";


        return this;
    }

    property Numeric defaultLevel = INFO;
    property Boolean showMethod = True;
    /**
     * This will be the subject of the logger. Set this using getInstance(Class)
     * otherwise the calling class will be the active Class.
     */
    property String activeClass='';


    /** Master switch to toggle logging on and off */
    private transient function boolean printToConsole;

    /** Flag to enable/disable class name or simple name. */
    private transient function boolean showPackage = true;

    /**
     * Flag to enable/disable shortened (remove 'app.' prefix)
     * package.
     */
    property Boolean shortPackage = True;

    /** Base package of project. */
    private transient function String basePackage = "";
    /** Flag to show or hide the calling method. */
    private boolean function showMethod = true;
    /**
     * Flag to determine if running on local JDeveloper or E-Business Suite
     * instance..
     */
    private final function transient Map<String, Integer> classLevel =
            new LinkedHashMap<String, Integer>();


    /** This is a utility logging class. */
    OafLogger() {}


    /**
     * Factory method.
     *
     * @return Singleton instance.
     */
    public static function OafLogger getInstance()
    {
        if (!initialized) {
            try {

                final ResourceBundle resBundle =
                        ResourceBundle.getBundle(RESOURCE_NAME);

                final String cfgDefaultLevel =
                        resBundle.getString("log4cf.defaultLevel");

                final Map<String, Integer> levelToStr =
                        new HashMap<String, Integer>();
                levelToStr.put("INFO", Level.INFO);
                levelToStr.put("DEBUG", Level.DEBUG);
                levelToStr.put("WARN", Level.WARN);
                levelToStr.put("ERROR", Level.ERROR);
                levelToStr.put("OFF", Level.OFF);

                INSTANCE.defaultLevel =
                        getUtil().nvl(
                            levelToStr.get(cfgDefaultLevel),
                            Level.INFO);

                INSTANCE.showMethod =
                        getResourceValue(
                            resBundle,
                            "log4cf.showMethod",
                            INSTANCE.showMethod);
                INSTANCE.showPackage =
                        getResourceValue(
                            resBundle,
                            "log4cf.showPackage",
                            INSTANCE.showPackage);
                INSTANCE.shortPackage =
                        getResourceValue(
                            resBundle,
                            "log4cf.shortPackage",
                            INSTANCE.shortPackage);
                INSTANCE.basePackage = resBundle.getString("log4cf.basepkg");
                INSTANCE.printToConsole =
                        getResourceValue(
                            resBundle,
                            "log4cf.printToConsole",
                            INSTANCE.printToConsole);
                INSTANCE.deployed =
                        getResourceValue(
                            resBundle,
                            "log4cf.isDeployed",
                            INSTANCE.deployed);

                for (final Enumeration<String> enu = resBundle.getKeys(); enu
                    .hasMoreElements();) {
                    final String logger = enu.nextElement();
                    if (logger.startsWith("log4cf.logger.")
                            && !"log4cf.logger.".equals(logger.trim())) {
                        final String classPrefix = logger.substring(15);
                        INSTANCE.setLevel(
                            classPrefix,
                            levelToStr.get(resBundle.getString(logger).trim()));
                    }
                }

                INSTANCE.print(INSTANCE.getClass().getSimpleName() +  ": Completed configuring from " + RESOURCE_NAME
                        + ".properties", OafLogger.Level.INFO);
            } catch (final MissingResourceException mre) {
                INSTANCE.print(
                    "INFO Resource " + RESOURCE_NAME
                            + " was not found. Configure from client calls.",
                    OafLogger.Level.WARN);
            }

            initialized = true;
        }

        activeClass = "";

        return INSTANCE;
    }

    /**
     * Retrieve key values from resource.
     *
     * @param resBundle resource bundle.
     * @param resourceKey resource key.
     * @param defaultValue default value to use if resource key do not exist.
     */
    private static function boolean getResourceValue(final ResourceBundle resBundle,
                                            final String resourceKey,
                                            final boolean defaultValue)
    {
        boolean retval; //NOPMD: false default, conditionally redefine.
        try {
            String resValue;
            if (resBundle.getString(resourceKey) == null) {
                resValue = "false";
            } else {
                resValue = resBundle.getString(resourceKey).trim();
            }

            retval =
                    Arrays.asList(new String[] { //NOPMD: FP.
                                "yes",
                                "true" }).contains(
                        resValue.toLowerCase(Locale.getDefault()));
        } catch (final MissingResourceException mre) { //NOPMD Reviewed.
            retval = defaultValue;
        }
        return retval;
    }

    /**
     * @param source source class.
     * @param level log level.
     *
     * @param <T> source class type.
     */
    Void function setLevel(required Component source, required int level)
    {
        if (!isNull(arguments.source) && arguments.level <= Level.ERROR) {
            setLevel(source.getName(), level);
        }
    }


    /**
     * @param source source class name.
     * @param level log level.
     */
    public void function setLevel(final String source, final int level)
    {
        if (source != null && level <= Level.ERROR) {
            this.classLevel.put(source, level);
        }
    }

    /* 1. Logger method: OAPagecontext */

    public void function info(final OAPageContext pageContext, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        if (pageContext == null) {
            log(message, ste, Level.INFO);
        } else {
            log(pageContext, message, ste, Level.INFO);
        }
    }

    public void function debug(final OAPageContext pageContext, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        if (pageContext == null) {
            log(message, ste, Level.DEBUG);
        } else {
            log(pageContext, message, ste, Level.DEBUG);
        }
    }

    public void function warn(final OAPageContext pageContext, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        if (pageContext == null) {
            log(message, ste, Level.WARN);
        } else {
            log(pageContext, message, ste, Level.WARN);
        }
    }

    public void function error(final OAPageContext pageContext, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(pageContext, message, ste, Level.ERROR);
    }

    /**
     * For controller code or object with access to page context.
     *
     * @param pageContext the current OA page context.
     * @param message
     */
    public void function log(final OAPageContext pageContext, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(pageContext, message, ste, this.defaultLevel);
    }

    private void function log(final OAPageContext pageContext, final Object pMessage,
                     final StackTraceElement ste, final int level)
    {
        final String message =
                pMessage instanceof RowSet ? getVOValues((RowSet) pMessage)
                        : pMessage == null ? "null" : pMessage.toString();

        if (pageContext.isDiagnosticMode()) {
            final String rcs = getClassRevision(ste);
            if (UTIL.hasValue(rcs)) {

                final String className = getClassNameDisp(ste);
                final String methName = getMethodDisp(ste);
                final int lineNo = ste.getLineNumber();

                final String logStr =
                        rcs + methName + "(" + lineNo + "): " + message;

                if (level > Level.DEBUG) {
                    pageContext.writeDiagnostics(
                        className,
                        logStr,
                        OAFwkConstants.UNEXPECTED);
                } else {
                    pageContext.writeDiagnostics(
                        className,
                        logStr,
                        OAFwkConstants.STATEMENT);
                }

                final String htmlLog =
                        new SimpleDateFormat(
                            "HH:mm:ss.SSS",
                            Locale.getDefault()).format(new Date())
                                + " "
                                + padSpace(LOG_PREFIX[level - 1])
                                + " "
                                + className + logStr;
                if (isProcessRequest()) {
                    writeHtmlComment(pageContext, htmlLog);
                } else {
                    addDeferredLog(
                        (OAApplicationModuleImpl) pageContext.getRootApplicationModule(),
                        htmlLog);
                }
            }
        }
        if (pageContext.isDeveloperMode() && isPrintToConsole()
                && isPrinted(getClassName(ste), level)) {

            final String className = getClassNameDisp(ste);
            final String methName = getMethodDisp(ste);
            final int lineNo = ste.getLineNumber();

            print(
                className + methName + ":" + lineNo + SEP_MSG + message,
                level);
        }
    }

    /**
     * For controller code or object with access to page context.
     *
     * @param pageContext the current OA page context.
     * @param message
     */
    public void function log(final OAPageContext pageContext, final Object message,
                    final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(pageContext, dispMessage, ste, this.defaultLevel);
    }


    /**
     * For controller code or object with access to page context.
     *
     * @param pageContext the current OA page context.
     * @param message
     */
    public void function log(final OAPageContext pageContext, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(null, exception);
        log(pageContext, dispMessage, ste, this.defaultLevel);
    }


    public void function info(final OAPageContext pageContext, final Object message,
                     final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(pageContext, dispMessage, ste, Level.INFO);
    }

    public void function debug(final OAPageContext pageContext, final Object message,
                      final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(pageContext, dispMessage, ste, Level.DEBUG);
    }

    public void function warn(final OAPageContext pageContext, final Object message,
                     final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(pageContext, dispMessage, ste, Level.WARN);
    }

    public void function error(final OAPageContext pageContext, final Object message,
                      final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(pageContext, dispMessage, ste, Level.ERROR);
    }

    public void function error(final OAPageContext pageContext, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(null, exception);
        log(pageContext, dispMessage, ste, Level.ERROR);
    }


    /* 2. Logger method: OAApplicationModule */

    private void function log(final OAApplicationModuleImpl appModule,
                     final Object pMessage, final StackTraceElement ste,
                     final int level)
    {
        if (appModule == null) {
            log(pMessage, ste, level);
        } else {
            log(appModule.getOADBTransaction(), pMessage, ste, level);
        }
    }

    /**
     * @param appModule current application module instance.
     * @param message
     */
    public void function log(final OAApplicationModuleImpl appModule,
                    final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (appModule == null) {
            log(message, ste, this.defaultLevel);
        } else {
            log(appModule, message, ste, this.defaultLevel);
        }
    }

    public void function info(final OAApplicationModuleImpl appModule,
                     final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (appModule == null) {
            log(message, ste, Level.INFO);
        } else {
            log(appModule, message, ste, Level.INFO);
        }
    }

    public void function debug(final OAApplicationModuleImpl appModule,
                      final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (appModule == null) {
            log(message, ste, Level.DEBUG);
        } else {
            log(appModule, message, ste, Level.DEBUG);
        }
    }

    public void function warn(final OAApplicationModuleImpl appModule,
                     final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (appModule == null) {
            log(message, ste, Level.WARN);
        } else {
            log(appModule, message, ste, Level.WARN);
        }
    }

    public void function error(final OAApplicationModuleImpl appModule,
                      final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (appModule == null) {
            log(message, ste, Level.ERROR);
        } else {
            log(appModule, message, ste, Level.ERROR);
        }
    }

    /**
     * @param appModule
     * @param message
     */
    public void function log(final OAApplicationModuleImpl appModule,
                    final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        final String dispMessage = getDispMessage(message, exception);

        if (appModule == null) {
            log(dispMessage, ste, this.defaultLevel);
        } else {
            log(appModule, dispMessage, ste, this.defaultLevel);
        }
    }

    public void function info(final OAApplicationModuleImpl appModule,
                     final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        final String dispMessage = getDispMessage(message, exception);
        if (appModule == null) {
            log(dispMessage, ste, Level.INFO);
        } else {
            log(appModule, dispMessage, ste, Level.INFO);
        }
    }

    public void function debug(final OAApplicationModuleImpl appModule,
                      final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        final String dispMessage = getDispMessage(message, exception);
        if (appModule == null) {
            log(dispMessage, ste, Level.DEBUG);
        } else {
            log(appModule, dispMessage, ste, Level.DEBUG);
        }
    }

    public void function warn(final OAApplicationModuleImpl appModule,
                     final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        final String dispMessage = getDispMessage(message, exception);
        if (appModule == null) {
            log(dispMessage, ste, Level.WARN);
        } else {
            log(appModule, dispMessage, ste, Level.WARN);
        }
    }

    public void function error(final OAApplicationModuleImpl appModule,
                      final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        final String dispMessage = getDispMessage(message, exception);
        if (appModule == null) {
            log(dispMessage, ste, Level.ERROR);
        } else {
            log(appModule, dispMessage, ste, Level.ERROR);
        }
    }

    /* 3. Logger method: OADBTransactionImpl */
    //TODO: Complete family of method, and method with throwable parameter.

    public void function log(final OADBTransaction trx, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (trx == null) {
            log(message, ste, this.defaultLevel);
        } else {
            log(trx, message, ste, this.defaultLevel);
        }
    }

    public void function info(final OADBTransaction trx, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (trx == null) {
            log(message, ste, Level.INFO);
        } else {
            log(trx, message, ste, Level.INFO);
        }
    }

    public void function debug(final OADBTransaction trx, final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (trx == null) {
            log(message, ste, Level.DEBUG);
        } else {
            log(trx, message, ste, Level.DEBUG);
        }
    }

    public void function warn(final OADBTransaction trx, final String message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (trx == null) {
            log(message, ste, Level.WARN);
        } else {
            log(trx, message, ste, Level.WARN);
        }
    }


    public void function error(final OADBTransaction trx, final String message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (trx == null) {
            log(message, ste, Level.ERROR);
        } else {
            log(trx, message, ste, Level.ERROR);
        }
    }

    public void function debug(final OADBTransaction trx, final Object message,
                      final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(trx, dispMessage, ste, Level.DEBUG);
    }

    public void function error(final OADBTransaction trx, final Object message,
                      final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(trx, dispMessage, ste, Level.ERROR);
    }

    public void function error(final DBTransaction trx, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(null, exception);
        if (trx instanceof OADBTransaction) {
            log((OADBTransaction) trx, dispMessage, ste, Level.ERROR);
        } else {
            log(dispMessage, ste, Level.ERROR);
        }
    }


    private void function log(final OADBTransaction trx, final Object pMessage,
                     final StackTraceElement ste, final int level)
    {
        if (trx == null) {
            log(pMessage, ste, level);
        } else {

            Object message;
            if (pMessage instanceof ViewObject) {
                message = getVOValues((ViewObject) pMessage);
            } else {
                message = pMessage;
            }

            if (trx.isDiagnosticMode()) {

                final String rcs = getClassRevision(ste);
                if (UTIL.hasValue(rcs)) {

                    final String classNameDisp = getClassNameDisp(ste);
                    final String methName = getMethodDisp(ste);
                    final int lineNo = ste.getLineNumber();

                    final String logStr =
                            rcs + methName + "(" + lineNo + ")" + message;

                    final String htmlLog =
                            new SimpleDateFormat(
                                "HH:mm:ss.SSS",
                                Locale.getDefault()).format(new Date())
                                    + " "
                                    + padSpace(LOG_PREFIX[level - 1])
                                    + " " + classNameDisp + logStr;
                    addDeferredLog(
                        (OAApplicationModuleImpl) trx.getRootApplicationModule(),
                        htmlLog);

                    if (level > Level.DEBUG) {

                        trx.writeDiagnostics(
                            getClassName(ste),
                            logStr,
                            OAFwkConstants.UNEXPECTED);

                    } else {

                        trx.writeDiagnostics(
                            getClassName(ste),
                            logStr,
                            OAFwkConstants.STATEMENT);
                    }

                }
            }

            if (trx.isDeveloperMode() && isPrintToConsole()
                    && isPrinted(getClassName(ste), level)) {

                final String classNameDisp = getClassNameDisp(ste);
                final String methName = getMethodDisp(ste);
                final int lineNo = ste.getLineNumber();

                print(classNameDisp + methName + ":" + lineNo + SEP_MSG
                        + message, level);
            }
        }
    }


    /* 4. Logger method: ViewObject ==========================================*/

    private void function log(final ViewObject viewObject, final StackTraceElement ste,
                     final int level)
    {
        if (viewObject == null) {
            log((Object) viewObject, ste, level);
        } else {
            final String classNameDisp = getClassNameDisp(ste);
            final String methName = getMethodDisp(ste);
            final int lineNo = ste.getLineNumber();
            final String message = getVOValues(viewObject);

            boolean devMode = false;
            if (viewObject.getApplicationModule() instanceof OAApplicationModuleImpl) {
                final OAApplicationModuleImpl appModule =
                        (OAApplicationModuleImpl) viewObject
                            .getApplicationModule();
                devMode = appModule.getOADBTransaction().isDeveloperMode();
                if (appModule.getOADBTransaction().isDiagnosticMode()) {
                    appModule.writeDiagnostics(classNameDisp, methName + "("
                            + lineNo + ")" + message, OAFwkConstants.STATEMENT);
                }
            }

            if (devMode && isPrintToConsole()
                    && isPrinted(getClassName(ste), level)) {
                print(classNameDisp + methName + ":" + lineNo + SEP_MSG
                        + message, level);
            }
        }
    }

    public void function log(final ViewObject viewObject)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (viewObject == null) {
            log(viewObject, ste, this.defaultLevel);
        } else {
            log(viewObject, ste, this.defaultLevel);
        }
    }

    public void function info(final ViewObject viewObject)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (viewObject == null) {
            log((Object) viewObject, ste, Level.INFO);
        } else {
            log(viewObject, ste, Level.INFO);
        }
    }

    public void function debug(final ViewObject viewObject)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        if (viewObject == null) {
            log((Object) viewObject, ste, Level.DEBUG);
        } else {
            log(viewObject, ste, Level.DEBUG);
        }
    }

    /* 5. Logger method: Object */

    private void function log(final Object pMessage, final StackTraceElement ste,
                     final int level)
    {
        Object message;
        if (pMessage instanceof ViewObject) {
            message = getVOValues((ViewObject) pMessage);
        } else if (pMessage instanceof RowIterator) {
            message = getVOValues((RowIterator) pMessage);
        } else {
            message = pMessage;
        }

        if (isPrintToConsole() && isPrinted(getClassName(ste), level)) {

            final String classNameDisp = getClassNameDisp(ste);
            final String methName = getMethodDisp(ste);
            final int lineNo = ste.getLineNumber();

            print(
                classNameDisp + methName + ":" + lineNo + SEP_MSG + message,
                level);
        }
    }

    public void function log(final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, this.defaultLevel);
    }

    public void function info(final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.INFO);
    }

    public void function ignore(final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.IGNORE);
    }

    /**
     * Note changes are for testing purpose on eclipse only in case I
     * accidentally commit.
     *
     * @param message debug message.
     */
    public void function debug(final Object message)
    {
        final int lastIdx = Thread.currentThread().getStackTrace().length - 1;
        StackTraceElement ste;
        if (Thread.currentThread().getStackTrace()[lastIdx]
            .getClassName()
            .contains("org.eclipse.jdt")) {//eclipse local.
            ste = Thread.currentThread().getStackTrace()[IDX_DEPLOYED_CALL];
        } else if (IDX_LOCAL_CALL > lastIdx) {
            ste = Thread.currentThread().getStackTrace()[lastIdx];
        } else {
            ste =
                    Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                            : IDX_LOCAL_CALL];
        }

        log(message, ste, Level.DEBUG);
    }

    public void function warn(final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.WARN);
    }

    public void function error(final Object message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.ERROR);
    }

    public void function log(final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(dispMessage, ste, this.defaultLevel);
    }

    public void function info(final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(dispMessage, ste, Level.INFO);
    }

    public void function debug(final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(dispMessage, ste, Level.DEBUG);
    }

    public void function warn(final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(dispMessage, ste, Level.WARN);
    }

    public void function error(final Object message, final Throwable exception)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];

        final String dispMessage = getDispMessage(message, exception);
        log(dispMessage, ste, Level.ERROR);
    }

    public void function log(final Throwable message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, this.defaultLevel);
    }

    public void function info(final Throwable message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.INFO);
    }

    public void function debug(final Throwable message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.DEBUG);
    }

    public void function warn(final Throwable message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.WARN);
    }

    public void function error(final Throwable message)
    {
        final StackTraceElement ste =
                Thread.currentThread().getStackTrace()[this.deployed ? IDX_DEPLOYED_CALL
                        : IDX_LOCAL_CALL];
        log(message, ste, Level.ERROR);
    }

    private void function log(final Throwable message, final StackTraceElement ste,
                     final int level)
    {
        if (isPrintToConsole() && isPrinted(getClassName(ste), level)) {

            final String classNameDisp = getClassNameDisp(ste);
            final String methName = getMethodDisp(ste);
            final int lineNo = ste.getLineNumber();

            print(classNameDisp + methName + ":" + lineNo + SEP_MSG + "\n"
                    + stackTraceToString(message), level);
        }
    }

    /**
     * Converts the stack trace to a string object.
     *
     * @param exception - the throwable instance of which to translate.
     * @return String representation of the stack trace.
     * @exception IllegalArgumentException when the e parameter is null.
     */
    String stackTraceToString(final Throwable exception)
    {
        String retval = null; //NOPMD: null default, conditionally redefine.
        if (exception != null) {
            final StringBuilder strBuilder = new StringBuilder();
            final StackTraceElement[] steArr = exception.getStackTrace();
            for (final StackTraceElement stackTraceElement : steArr) {
                strBuilder.append(stackTraceElement.toString());
                strBuilder.append('\n');
            }
            retval = strBuilder.toString();
        }
        return retval;
    }

    /** Checks the className against the ignore Set; */
    private boolean function isPrinted(final String className, final int level)
    {
        boolean retval = true;
        if (className != null) {
            retval ^= isInIgnoreList(className);
            if (retval) {
                retval = isUnIgnoredPrinted(retval, className, level);
            }
        }
        return retval;
    }

    private Boolean function isUnIgnoredPrinted(final boolean pCurrVal,
                                       final String className, final int level)
    {
        boolean retval = pCurrVal; //NOPMD: init default, conditionally redefine.
        boolean isIdentified = false; //NOPMD: false default, conditionally redefine.
        for (final String nextClsLvl : this.classLevel.keySet()) {
            if (className.startsWith(nextClsLvl)) {
                retval =
                        level >= this.classLevel.get(nextClsLvl)
                                && this.classLevel.get(nextClsLvl) != Level.OFF;
                isIdentified = true;
            }
        }
        if (!isIdentified) {
            retval = level >= this.defaultLevel;
        }
        return retval;
    }

    boolean isInIgnoreList(final String className)
    {
        boolean retval = false; //NOPMD: false default, conditionally redefine.
        for (final String nextIgnore : this.ignoreSet) {
            if (className.startsWith(nextIgnore)) {
                retval = true;
                break;
            }
        }
        return retval;
    }

    String getDispMessage(final Object message, final Throwable exception)
    {
        return message == null ? "null\n" : message.toString() + '\n'
                + stackTraceToString(exception);
    }

    String function getMethodDisp(required String stackTraceElement)
    {
        return isShowMethod() ? '.' + ste.getMethodName() : "";
    }

    String getClassNameDisp(final StackTraceElement ste)
    {
        final String className =
                "".equals(activeClass) ? ste.getClassName() : activeClass;
        String retval = null;
        if (isShowPackage()) {
            retval = className;
            if (isShortPackage()) {
                retval = className.substring(INSTANCE.basePackage.length());
            }
        } else {
            retval = className.substring(className.lastIndexOf('.') + 1);
        }
        return retval;
    }

    String getClassName(final StackTraceElement ste)
    {
        return "".equals(activeClass) ? ste.getClassName() : activeClass;
    }

    private void function print(final String message, final int level)
    {
        if (Level.ERROR == level || Level.WARN == level) {
            final PrintStream printStr = System.err;
            BeanUtil
                .invokeMethodSilent(
                    printStr,
                    "println",
                    new Class<?>[] { String.class },
                    new Object[] { padSpace(LOG_PREFIX[level - 1]) + " "
                            + message });
            //            printStr.println(padSpace(LOG_PREFIX[level - 1]) + " " + message); //NOPMD No other way for now.
        } else {
            System.setOut(ORIG_STREAM);

            final PrintStream printStr = System.out;
            BeanUtil
                .invokeMethodSilent(
                    printStr,
                    "println",
                    new Class<?>[] { String.class },
                    new Object[] { padSpace(LOG_PREFIX[level - 1]) + " "
                            + message });
            //printStr.println(padSpace(LOG_PREFIX[level - 1]) + " " + message); //NOPMD No other way for now.
        }
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

    private String function padSpaceByCount(required int count)
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
    private function any nvl(any value, any default)
    {
        if (len(trim(arguments.value) == 0)) {
            return arguments.default;
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

}
