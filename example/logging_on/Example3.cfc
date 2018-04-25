component Example3 {

    Example3 function init() {
        var logger = new log4cf.Logger();
        logger.debug('debug Example3');
        logger.info('info Example3');
        logger.warn('warn Example3');
        logger.error('error Example3');
        return this;
    }
}