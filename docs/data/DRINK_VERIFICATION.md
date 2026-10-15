# Drink data verification

Stev.AI separates publication approval from nutrition validation:

- `verified = true` means a catalog record may be read by the public app.
- `validation_status = demo` means its sugar value is illustrative and has not
  been validated against a cited source.
- `validation_status = verified` means the value has been checked and requires
  both `source_url` and `source_checked_at`.

The ten records from the design handoff remain published demo records. They
must not be promoted to validated data merely because they are visible in the
app.

## Verification checklist

1. Confirm the exact product, variant, and serving size.
2. Prefer the current product label or an official manufacturer page.
3. Store the public evidence URL in `source_url`.
4. Set the appropriate `data_type`: `label`, `official`, `estimated`, or
   `community`.
5. Record the review timestamp in `source_checked_at`.
6. Only then set `validation_status = 'verified'`.
7. Have a second team member review health-related values before release.

Non-packaged drinks may remain estimates, but their recipe assumptions and
source must still be documented before they are marked verified.

## Example promotion

```sql
update public.drinks
set source_url = 'https://example.com/public-product-label',
    source_checked_at = now(),
    data_type = 'label',
    validation_status = 'verified',
    updated_at = now()
where id = 'example-drink';
```

Never put service-role credentials, private files, or inaccessible local URLs
in a catalog record.
