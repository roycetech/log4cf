component Example4 {

    Example4 function init() {
        var logger = new log4cf.Logger('banana');
        logger.debug('debug Example4');
        logger.info('info Example4');
        logger.warn('warn Example4');
        logger.error('error Example4');

        logger.debug('banana debug Example4');
        logger.info('banana info Example4');
        logger.warn('banana warn Example4');
        logger.error('banana error Example4');

        return this;
    }
}