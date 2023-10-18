CREATE OR REPLACE PROCEDURE distribute_city_bonus(v_city_id NUMBER) 
IS
  v_city_bonus NUMBER;
  v_branch_count NUMBER;
BEGIN
  -- Fetch bonus for the city
  SELECT city_bonus INTO v_city_bonus FROM cities WHERE city_id = v_city_id;
  -- Get number of branches in the city
  SELECT COUNT(*) INTO v_branch_count FROM branches WHERE city_id = v_city_id;
  -- Calculate bonus for the branch
  FOR branch_record IN (SELECT branch_id FROM branches WHERE city_id = v_city_id)
  LOOP
    -- Calculate bonus for the branch using a function
    UPDATE branches SET branch_bonus = calculate_branch_bonus(v_city_bonus, v_branch_count)
     WHERE branch_id = branch_record.branch_id;
  END LOOP;
END;
/

CREATE OR REPLACE FUNCTION calculate_branch_bonus(v_city_bonus NUMBER, v_branch_count NUMBER) 
RETURN NUMBER
IS
  v_bonus_for_branch NUMBER;
BEGIN
  -- Calculate bonus for each branch
  v_bonus_for_branch := v_city_bonus / v_branch_count;
  
  RETURN v_bonus_for_branch;
END;
/
CREATE OR REPLACE PROCEDURE distribute_branch_bonus(v_branch_id NUMBER)
IS
  CURSOR emp_cursor IS
    SELECT employee_id
      FROM branch_employees
      WHERE branch_id = v_branch_id;
  
  v_emp_id NUMBER;
  v_bonus NUMBER;
  v_mgr_bonus NUMBER;
  v_emp_bonus NUMBER;
  v_mgr_count NUMBER;
  v_emp_count NUMBER;
BEGIN
  -- Get the total branch bonus
  SELECT branch_bonus INTO v_bonus
    FROM branches
    WHERE branch_id = v_branch_id;
    
  -- Get the count of manager in the branch
  SELECT COUNT(*) INTO v_mgr_count
    FROM branch_employees
    WHERE employee_position = 'MGR' AND branch_id = v_branch_id;
    
  -- Calculate the manager bonus
  v_mgr_bonus := v_bonus * 0.5/v_mgr_count;
  
  -- Get the number of employee in the branch
  SELECT COUNT(*) INTO v_emp_count
    FROM branch_employees
    WHERE employee_position = 'EMP' AND branch_id = v_branch_id;
    
  -- Calculate the employee bonus
  v_emp_bonus := v_bonus *0.5/v_emp_count;

  -- loop through the employees in the branch
  FOR emp_rec IN emp_cursor LOOP
    -- Update the employee bonus
    UPDATE branch_employees
      SET employee_bonus =
       CASE
        WHEN employee_position = 'MGR' THEN v_mgr_bonus
        ELSE v_emp_bonus
      END
      WHERE employee_id = emp_rec.employee_id;
  END LOOP;
END;


-- Calling the procedure
DECLARE
  CURSOR city_cursor IS
    SELECT city_id FROM cities;
BEGIN
  FOR city_record IN city_cursor LOOP
    distribute_city_bonus(city_record.city_id);
  END LOOP;
END;

DECLARE
  CURSOR branch_cursor IS
    SELECT branch_id
      FROM branches;
  
  v_branch_id NUMBER;
BEGIN
  -- Loop through the branches
  FOR branch_rec IN branch_cursor LOOP
    -- Get the branch id
    v_branch_id := branch_rec.branch_id;

    -- Call the procedure
    distribute_branch_bonus(v_branch_id);
  END LOOP;
END;