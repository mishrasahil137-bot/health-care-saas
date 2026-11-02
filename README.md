# HEALTH CARE — Clinic, Pharmacy & Laboratory CRM SaaS

A multi-tenant healthcare operations platform for independent clinics, pharmacies and diagnostic laboratories. Built with Node.js, Express, PostgreSQL and a responsive browser UI.

## Included workflows

- **SaaS administration:** platform Super Admin, customer workspace provisioning, activation/suspension, per-workspace admin login.
- **Clinic CRM:** patient registry, doctor directory, appointment scheduling, prescriptions, clinic invoices and payment status.
- **Pharmacy:** medicine catalogue, SKU/barcode fields, batch and expiry fields, supplier directory, purchase entry with atomic stock-in, pharmacy sales with row-locked stock deduction, low-stock and expiry alerts.
- **Laboratory:** test catalogue, sample type, department, price and turnaround time; patient-linked lab orders, priority/status tracking and structured results.
- **Business operations:** expenses, dashboard, monthly sales/collection reports, audit events and invoice payment collection.
- **Tenant separation:** tenant-scoped data access; patient, doctor, supplier and medicine references are checked against the authenticated workspace.

## Local setup

1. Use Node.js 20+ and PostgreSQL 14+.
2. Create a PostgreSQL database, e.g. `health_care`.
3. Copy `.env.example` to `.env`; set a unique 32+ character `JWT_SECRET`, `DATABASE_URL`, `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD` (12+ characters).
4. Run `npm ci`.
5. Run `npm run db:migrate`.
6. Run `npm run seed` once to create the platform Super Admin.
7. Run `npm start`; open `http://localhost:3000`.

## Deploy to Render

A `render.yaml` Blueprint provisions a Node web service and PostgreSQL in the same region. Review the selected plans and estimated charges in Render before applying. Set `SUPER_ADMIN_EMAIL`, `SUPER_ADMIN_PASSWORD`, and `JWT_SECRET` as secrets. The web service runs migrations on startup and seeds the Super Admin only if the configured email does not already exist.

## Pharmacy transaction format

Purchase API `POST /api/purchases` accepts `supplier_id`, `invoice_no`, `notes`, and `items`:

```json
{
  "supplier_id": 4,
  "invoice_no": "SUP-INV-104",
  "items": [
    {"medicine_id": 12, "qty": 50, "purchase_price": 8.5, "batch_no": "B24", "expiry_date": "2028-05-31"}
  ]
}
```

Pharmacy invoice `POST /api/invoices` accepts `kind: "pharmacy"`, patient_id (optional), tax, discount, paid, payment_method and items containing `medicine_id`, `qty`, and `price`. Stock is checked and deducted in the same database transaction as invoice creation. Clinic invoices use `kind: "clinic"` and line items with `name`, `qty`, and `price`.

## Laboratory order format

Create lab tests in the test catalogue, then create a `lab_orders` record with `patient_id`, optional `doctor_id`, `test_ids` (array of test IDs), `priority`, `status`, `clinical_notes`, and `results` (JSON object). The authenticated workspace is enforced on all linked records.

## Operational safety

This is practice-management software, not a diagnostic decision engine. Lab results and prescriptions must be entered/reviewed by qualified professionals. Before processing real patient data or commercial rollout, complete a third-party security assessment, test restore procedures and encrypted backups, configure monitoring and retention/deletion policies, and have qualified Indian legal/accounting/pharmacy professionals validate applicable DPDP, clinical-establishment, GST, biomedical-waste and pharmacy recordkeeping obligations. This build does not claim regulatory certification or replace statutory registers / controlled-drug workflows where required. Avoid using a free/ephemeral database for production patient records.

## Environment

See `.env.example`. Never commit `.env`, credentials, patient data or real production secrets.
