component Example5 {

    Example5 function init() {
        var logger = new log4cf.Logger('potato');
        logger.debug('debug Example5');
        logger.info('info Example5');
        logger.warn('warn Example5');
        logger.error('error Example5');

        logger.debug('potato debug Example5');
        logger.info('potato info Example5');
        logger.warn('potato warn Example5');
        logger.error('potato error Example5');

        return this;
    }
}