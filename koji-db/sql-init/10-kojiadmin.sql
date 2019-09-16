
-- Create 'kojiadmin' account
INSERT INTO users (name, usertype, status) VALUES ('kojiadmin', 0, 0);

-- Make kojiadmin an actual admin
INSERT INTO user_perms (user_id, perm_id, creator_id)
      SELECT users.id, permissions.id, users.id FROM users, permissions
      WHERE users.name = 'kojiadmin'
            AND permissions.name = 'admin';
