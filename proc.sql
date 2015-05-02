--
--
--
drop procedure p3.test2@
drop procedure p3.test1@
--
--
CREATE PROCEDURE p3.test1 
(IN jobName CHAR(8), OUT jobCount INTEGER)
LANGUAGE SQL
  BEGIN
    DECLARE SQLSTATE CHAR(5);

    declare c1 cursor for
      SELECT count(jobName) 
        from employee 
      where job = jobName;
    
    open c1;
    fetch c1 into jobCount;
    close c1;

END @

CREATE PROCEDURE p3.test2 
(IN jobName CHAR(8), OUT jobCount INTEGER)
LANGUAGE SQL
  BEGIN
    DECLARE SQLSTATE CHAR(5);
    DECLARE v_count integer;

    CALL p3.test1(jobName, v_count);
    set jobCount = v_count;

END @
 