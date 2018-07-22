component Example5 {

    Example5 function init() {
        var logger = new log4cf.Logger('potato');
        logger.debug('potato debug Example5');
        logger.info('potato info Example5');
        logger.warn('potato warn Example5');
        logger.error('potato error Example5');

        return this;
    }
}