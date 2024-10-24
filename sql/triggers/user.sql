-- Always set removed field to false on insertion
CREATE OR REPLACE FUNCTION set_removed_to_false() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    new.removed = FALSE;

    RETURN new;
END;
$$;

CREATE TRIGGER bi_user_set_removed_to_false
    BEFORE INSERT
    ON "user"
    FOR EACH ROW
EXECUTE PROCEDURE set_removed_to_false();



-- Deny modification of fields id, email or type
CREATE OR REPLACE FUNCTION user_deny_unmodifiable_fields_update() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF new.id != old.id THEN
        RAISE EXCEPTION 'Cannot modify id field.';
    END IF;

    IF new.email != old.email THEN
        RAISE EXCEPTION 'Cannot modify email field.';
    END IF;

    IF new.type != old.type THEN
        RAISE EXCEPTION 'Cannot modify type field.';
    END IF;

    RETURN new;
END;
$$;

CREATE TRIGGER bu_user_deny_unmodifiable_fields_update
    BEFORE UPDATE
    ON "user"
    FOR EACH ROW
EXECUTE PROCEDURE user_deny_unmodifiable_fields_update();



/**
  'removed' field can only go from FALSE to TRUE.
  Before setting 'removed' field to TRUE for a patron, the corresponding patron
  record must already be removed.
 */
CREATE OR REPLACE FUNCTION user_enforce_removal_policy() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    _patron_is_removed BOOLEAN;
BEGIN
    IF new.removed IS DISTINCT FROM old.removed THEN

        IF new.removed IS FALSE THEN
            RAISE EXCEPTION 'Removed users cannot be restored.';
        END IF;

        SELECT patron.removed
        FROM patron
        WHERE new.id = patron."user"
        INTO _patron_is_removed;

        IF NOT _patron_is_removed THEN
            RAISE EXCEPTION 'Before removing a patron user, the corresponding patron record must already be removed.';
        END IF;

    END IF;

    RETURN new;
END;
$$;

CREATE TRIGGER bu_user_enforce_removal_policy
    BEFORE UPDATE
    ON "user"
    FOR EACH ROW
EXECUTE PROCEDURE user_enforce_removal_policy();



-- Deny deletion of records
CREATE TRIGGER bd_user_deny_deletion
    BEFORE DELETE
    ON "user"
    FOR EACH ROW
EXECUTE PROCEDURE deny_deletion();