component Example2 {

    Example2 function init() {
        var logger = new log4cf.Logger();
        logger.debug('debug Example2');
        logger.info('info Example2');
        logger.warn('warn Example2');
        logger.error('error Example2');
        return this;
    }
}