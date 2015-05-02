DROP PROCEDURE CUST_CRT@
DROP PROCEDURE CUST_LOGIN@
DROP PROCEDURE ACCT_OPN@
DROP PROCEDURE ACCT_CLS@
DROP PROCEDURE ACCT_DEP@
DROP PROCEDURE ACCT_WTH@
DROP PROCEDURE ACCT_TRX@
DROP PROCEDURE ADD_INTEREST@

CREATE PROCEDURE CUST_CRT
(IN Name VARCHAR(15), IN Gender CHAR, IN Age INTEGER, IN Pin INTEGER, OUT ID INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	DECLARE v_Pin INTEGER;
	
	IF (Age < 0) THEN
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccesful. Age must be positive.';
	ELSE
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
		SET v_Pin = p3.encrypt(Pin);
		INSERT INTO p3.customer (Name, Gender, Age, Pin) VALUES(Name, Gender, Age, v_Pin);
		SET ID = (SELECT ID FROM p3.customer WHERE p3.customer.Name = Name AND p3.customer.Pin = v_Pin);
	END IF;
END@

CREATE PROCEDURE CUST_LOGIN
(IN cust_ID INTEGER, IN cust_Pin INTEGER, OUT Valid INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	DECLARE v_ID INTEGER;
	DECLARE v_Pin INTEGER;
	
	SET v_ID = (SELECT ID FROM p3.customer WHERE ID = cust_ID);
	SET v_Pin = (SELECT p3.decrypt(Pin) FROM p3.customer WHERE ID = cust_ID AND p3.decrypt(Pin) = cust_Pin);
	
	if (cust_ID = v_ID) AND (cust_Pin = v_Pin) THEN
		SET Valid = 1;
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
	ELSE 
		SET Valid = 0;
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Invalid ID or Pin.';
	END IF;
END@

CREATE PROCEDURE ACCT_OPN
(IN cust_ID INTEGER, IN cust_Balance INTEGER, IN cust_Type char, OUT "Number" INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	IF (cust_Balance < 0) THEN
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Balance must be positive.';
	ELSE
		INSERT INTO p3.account (Id, Balance, Type, Status) VALUES(cust_ID, cust_Balance, cust_Type, 'A');
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
		SET "Number" = (SELECT Max(Number) FROM p3.account);
	END IF;
END@

CREATE PROCEDURE ACCT_CLS
(IN cust_Number INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	DECLARE v_Number INTEGER;
	SET v_Number = (SELECT Number FROM p3.account WHERE Number=cust_Number);
	
	IF (v_Number = cust_Number) THEN
		UPDATE p3.account SET Balance='0', Status='I' WHERE Number=cust_Number;
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
	ELSE
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Account number does not exist.';
	END IF;
END@

CREATE PROCEDURE ACCT_DEP
(IN cust_Number INTEGER, IN Amt INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	DECLARE active char;
	SET active = (SELECT Status FROM p3.account WHERE Number=cust_Number);
	
	IF (Amt < 0) OR (active = 'I') THEN
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Amount must be positive and accout must be active.';
	ELSE
		UPDATE p3.account SET Balance = Balance + Amt WHERE Number=cust_Number;
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
	END IF;
END@

CREATE PROCEDURE ACCT_WTH
(IN cust_Number INTEGER, IN Amt INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	DECLARE active CHAR;
	DECLARE bal INTEGER;
	DECLARE valid INTEGER;
	
	SET active = (SELECT Status FROM p3.account WHERE Number=cust_Number);
	
	SET bal = (SELECT Balance FROM p3.account WHERE Number=cust_Number);
	
	IF (Amt > bal) THEN
		SET valid = -1;
	ELSE
		SET valid = 1;
	END IF;
	
	IF (Amt < 0) OR (active = 'I') OR (valid = -1) THEN
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Amount must be positive, accout must be active, and amount must not exceed balance.';
	ELSE
		UPDATE p3.account SET Balance = Balance - Amt WHERE Number=cust_Number;
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
	END IF;
END@

CREATE PROCEDURE ACCT_TRX
(IN Src_Acct INTEGER, IN Dest_Acct INTEGER, IN Amt INTEGER, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	DECLARE out_sqlcode INTEGER;
	DECLARE out_err_msg VARCHAR(255);
	
	DECLARE valid INTEGER;
	DECLARE src_active CHAR;
	DECLARE dest_active CHAR;
	DECLARE src_bal INTEGER;
	DECLARE v_Src_Acct INTEGER;
	DECLARE v_Dest_Acct INTEGER;
	
	SET src_active = (SELECT Status FROM p3.account WHERE Number=Src_Acct);
	SET dest_active = (SELECT Status FROM p3.account WHERE Number=Dest_Acct);
	SET src_bal = (SELECT Balance FROM p3.account WHERE Number=Src_Acct);
	SET v_Src_Acct = (SELECT Number FROM p3.account WHERE Number=Src_Acct);
	SET v_Dest_Acct = (SELECT Number FROM p3.account WHERE Number=Dest_Acct);
	
	IF (Src_Acct = Dest_Acct) OR (Amt < 0) OR (src_active = 'I') OR (dest_active = 'I') OR (Amt > src_bal) THEN
		SET valid = -1;
	ELSE
		SET valid = 1;
	END IF;
	
	IF (valid = 1) AND (v_Src_Acct = Src_Acct) AND (v_Dest_Acct = Dest_Acct) THEN
		CALL ACCT_WTH(Src_Acct, Amt, out_sqlcode, out_err_msg);
		CALL ACCT_DEP(Dest_Acct, Amt, out_sqlcode, out_err_msg);
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
	ELSE
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Amount must be positive, accounts must exist, accounts must be active, and amount may not exceed balance of source account.';
	END IF;
END@

CREATE PROCEDURE ADD_INTEREST
(IN Savings_Rate DOUBLE, IN Checking_Rate DOUBLE, OUT "sqlcode" INTEGER, OUT err_msg varchar(255))
LANGUAGE SQL
  BEGIN
	IF (Savings_Rate < 0) OR (Checking_Rate < 0) THEN
		SET "sqlcode" = -1;
		SET err_msg = 'Unsuccessful. Rates must be positive.';
	ELSE
		UPDATE p3.account SET Balance = Balance + (Balance * Savings_Rate) WHERE Type='S';
		UPDATE p3.account SET Balance = Balance + (Balance * Checking_Rate) WHERE Type='C';
		SET "sqlcode" = 0;
		SET err_msg = 'Successful.';
	END IF;
END@
