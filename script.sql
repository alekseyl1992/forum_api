SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

DROP SCHEMA IF EXISTS `forum_api` ;
CREATE SCHEMA IF NOT EXISTS `forum_api` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `forum_api` ;

-- -----------------------------------------------------
-- Table `forum_api`.`forum`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forum_api`.`forum` ;

CREATE TABLE IF NOT EXISTS `forum_api`.`forum` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `short_name` VARCHAR(255) NOT NULL,
  `user` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`short_name`),
  INDEX `id_key` (`id` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forum_api`.`user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forum_api`.`user` ;

CREATE TABLE IF NOT EXISTS `forum_api`.`user` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NULL,
  `username` VARCHAR(255) NULL,
  `email` VARCHAR(255) NOT NULL,
  `about` VARCHAR(1000) NULL,
  `isAnonymous` TINYINT(1) NOT NULL,
  UNIQUE INDEX `email_UNIQUE` (`email` ASC),
  PRIMARY KEY (`email`),
  INDEX `id_key` (`id` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forum_api`.`thread`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forum_api`.`thread` ;

CREATE TABLE IF NOT EXISTS `forum_api`.`thread` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL,
  `date` DATETIME NOT NULL,
  `isClosed` TINYINT(1) NOT NULL,
  `isDeleted` TINYINT(1) NOT NULL,
  `message` VARCHAR(1000) NOT NULL,
  `likes` INT UNSIGNED NOT NULL,
  `dislikes` INT UNSIGNED NOT NULL,
  `forum` VARCHAR(255) NOT NULL,
  `user` VARCHAR(255) NOT NULL,
  `posts` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  INDEX `fk_thread_forum1_idx` (`forum` ASC),
  INDEX `fk_thread_user1_idx` (`user` ASC),
  CONSTRAINT `fk_thread_forum1`
    FOREIGN KEY (`forum`)
    REFERENCES `forum_api`.`forum` (`short_name`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_thread_user1`
    FOREIGN KEY (`user`)
    REFERENCES `forum_api`.`user` (`email`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forum_api`.`post`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forum_api`.`post` ;

CREATE TABLE IF NOT EXISTS `forum_api`.`post` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `message` VARCHAR(1000) NOT NULL,
  `date` DATETIME NOT NULL,
  `isApproved` TINYINT(1) NOT NULL,
  `isEdited` TINYINT(1) NOT NULL,
  `isDeleted` TINYINT(1) NOT NULL,
  `isHighlighted` TINYINT(1) NOT NULL,
  `isSpam` TINYINT(1) NOT NULL,
  `likes` INT UNSIGNED NOT NULL,
  `dislikes` INT UNSIGNED NOT NULL,
  `thread` INT UNSIGNED NOT NULL,
  `parent` INT UNSIGNED NULL,
  `user` VARCHAR(255) NOT NULL,
  `forum` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_post_thread1_idx` (`thread` ASC),
  INDEX `fk_post_post1_idx` (`parent` ASC),
  INDEX `fk_post_user1_idx` (`user` ASC),
  INDEX `fk_post_forum1_idx` (`forum` ASC),
  CONSTRAINT `fk_post_thread1`
    FOREIGN KEY (`thread`)
    REFERENCES `forum_api`.`thread` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_post_post1`
    FOREIGN KEY (`parent`)
    REFERENCES `forum_api`.`post` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_post_user1`
    FOREIGN KEY (`user`)
    REFERENCES `forum_api`.`user` (`email`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_post_forum1`
    FOREIGN KEY (`forum`)
    REFERENCES `forum_api`.`forum` (`short_name`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forum_api`.`follow`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forum_api`.`follow` ;

CREATE TABLE IF NOT EXISTS `forum_api`.`follow` (
  `follower` VARCHAR(100) NOT NULL,
  `followee` VARCHAR(100) NOT NULL,
  INDEX `fk_follow_user1_idx` (`follower` ASC),
  INDEX `fk_follow_user2_idx` (`followee` ASC),
  PRIMARY KEY (`follower`, `followee`),
  INDEX `reverse_index` (`followee` ASC),
  CONSTRAINT `fk_follow_user1`
    FOREIGN KEY (`follower`)
    REFERENCES `forum_api`.`user` (`email`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_follow_user2`
    FOREIGN KEY (`followee`)
    REFERENCES `forum_api`.`user` (`email`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `forum_api`.`subscription`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `forum_api`.`subscription` ;

CREATE TABLE IF NOT EXISTS `forum_api`.`subscription` (
  `user` VARCHAR(255) NOT NULL,
  `thread_id` INT UNSIGNED NOT NULL,
  INDEX `fk_subscription_thread1_idx` (`thread_id` ASC),
  PRIMARY KEY (`user`, `thread_id`),
  CONSTRAINT `fk_subscription_thread1`
    FOREIGN KEY (`thread_id`)
    REFERENCES `forum_api`.`thread` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_subscription_user1`
    FOREIGN KEY (`user`)
    REFERENCES `forum_api`.`user` (`email`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
