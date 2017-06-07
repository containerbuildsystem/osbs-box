/* Why is this needed? */
/* INSERT INTO content_generator (name) VALUES ('test-cg'); */

/* Create users */
INSERT INTO users (name, status, usertype) VALUES
    ('kojiadmin', 0, 0);

/* Make some users admin */
INSERT INTO user_perms (user_id, perm_id, creator_id) (
    SELECT users.id, permissions.id, users.id FROM users, permissions
    WHERE users.name IN (
        'kojiadmin'
    ) AND permissions.name = 'admin'
);

/* Enable content generator */
INSERT INTO content_generator VALUES
    (1, 'atomic-reactor');
