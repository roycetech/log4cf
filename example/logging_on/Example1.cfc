component Example1 {

    any function init() {
        logger = new log4cf.Logger();
        logger.debug('debug Example1');
        logger.info('info Example1');
        logger.warn('warn Example1');
        logger.error('error Example1');

        return this;
    }
}