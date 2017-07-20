CREATE TABLE image_listing (
       image_id INTEGER NOT NULL REFERENCES image_archives(archive_id),
       rpm_id INTEGER NOT NULL REFERENCES rpminfo(id),
       UNIQUE (image_id, rpm_id)
) WITHOUT OIDS;

CREATE INDEX image_listing_rpms on image_listing(rpm_id);
