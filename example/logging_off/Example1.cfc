component Example1 {

    Example1 function init() {
        var logger = new log4cf.Log4Cf();
        logger.debug('debug Example1');
        logger.info('info Example1');
        logger.warn('warn Example1');
        logger.error('error Example1');
        return this;
    }
}