import csv
from datetime import datetime, timedelta
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / "data"
OUT_DIR.mkdir(parents=True, exist_ok=True)

first_names = [
    "Alex", "Taylor", "Jordan", "Morgan", "Casey", "Jamie", "Riley", "Avery", "Cameron", "Drew",
    "Ryan", "Sydney", "Parker", "Quinn", "Blake", "Harper", "Reese", "Skyler", "Rowan", "Devon",
    "Aiden", "Maya", "Noah", "Zoe", "Liam", "Nina", "Owen", "Leah", "Ethan", "Mia"
]
last_names = [
    "Anderson", "Brooks", "Carter", "Diaz", "Edwards", "Fisher", "Gonzalez", "Harris", "Ibrahim", "Jackson",
    "Kim", "Lewis", "Mills", "Nelson", "Owens", "Patterson", "Quinn", "Reynolds", "Stewart", "Turner"
]
cities = [
    ("New York", "NY"), ("Los Angeles", "CA"), ("Chicago", "IL"), ("Houston", "TX"), ("Phoenix", "AZ"),
    ("Philadelphia", "PA"), ("San Antonio", "TX"), ("San Diego", "CA"), ("Dallas", "TX"), ("San Jose", "CA")
]
medications = [
    "Lisinopril", "Metformin", "Atorvastatin", "Albuterol", "Levothyroxine", "Amlodipine", "Omeprazole",
    "Gabapentin", "Hydrochlorothiazide", "Sertraline"
]
encounter_types = ["Inpatient", "Emergency", "Outpatient", "Observation"]
doctors = ["Dr Adams", "Dr Baker", "Dr Clark", "Dr Davis", "Dr Evans", "Dr Foster", "Dr Grant", "Dr Hill"]
hospitals = ["H001", "H002", "H003", "H004", "H005"]
diagnosis_codes = ["I10", "E11.9", "J18.9", "N18.9", "I50.9", "M54.5", "K21.9", "J45.909"]
lab_tests = [
    ("GLU", "Blood Glucose", "mg/dL", 70, 180),
    ("A1C", "Hemoglobin A1C", "%", 4.5, 8.5),
    ("CRE", "Creatinine", "mg/dL", 0.6, 2.4),
    ("HGB", "Hemoglobin", "g/dL", 11.0, 17.5),
    ("K", "Potassium", "mmol/L", 3.5, 5.2)
]
claim_statuses = ["APPROVED", "DENIED", "PENDING"]

num_rows = 1000
base_date = datetime(2026, 1, 1)

def make_ssn(index: int) -> str:
    block1 = 100 + (index % 900)
    block2 = 10 + ((index // 900) % 90)
    block3 = 1000 + ((index // 9900) % 9000)
    return f"{block1:03d}-{block2:02d}-{block3:04d}"

patient_rows = []
for i in range(1, num_rows + 1):
    pid = f"P{2000 + i}"
    mrn = f"MRN{200000 + i:06d}"
    first = first_names[(i - 1) % len(first_names)]
    last = last_names[(i - 1) % len(last_names)]
    dob = base_date - timedelta(days=365 * (20 + ((i - 1) % 60)))
    gender = "F" if i % 2 == 0 else "M"
    ssn = make_ssn(i)
    phone = f"{200 + ((i - 1) % 800):03d}-{555 + ((i - 1) % 1000):03d}-{1000 + (i % 9000):04d}"
    email = f"{first.lower()}.{last.lower()}{i}@example.org"
    city, state = cities[(i - 1) % len(cities)]
    zip_code = f"{10000 + ((i - 1) % 90000):05d}"
    ingest = datetime(2026, 6, 11, 10, 0, 0) + timedelta(seconds=i)
    patient_rows.append([
        pid,
        mrn,
        first,
        last,
        dob.strftime("%Y-%m-%d"),
        gender,
        ssn,
        phone,
        email,
        f"{100 + ((i - 1) % 900):d} Main St",
        city,
        state,
        zip_code,
        ingest.strftime("%Y-%m-%d %H:%M:%S"),
    ])

encounter_rows = []
for i in range(1, num_rows + 1):
    eid = f"E{3000 + i}"
    pid = patient_rows[i - 1][0]
    admit = base_date + timedelta(days=(i - 1) % 180)
    length = 1 + ((i - 1) % 10)
    discharge = admit + timedelta(days=length)
    etype = encounter_types[(i - 1) % len(encounter_types)]
    doctor = doctors[(i - 1) % len(doctors)]
    hosp = hospitals[(i - 1) % len(hospitals)]
    diag = diagnosis_codes[(i - 1) % len(diagnosis_codes)]
    ingest = datetime(2026, 6, 11, 11, 0, 0) + timedelta(seconds=i)
    encounter_rows.append([
        eid,
        pid,
        admit.strftime("%Y-%m-%d"),
        discharge.strftime("%Y-%m-%d"),
        etype,
        doctor,
        hosp,
        diag,
        ingest.strftime("%Y-%m-%d %H:%M:%S"),
    ])

lab_rows = []
for i in range(1, num_rows + 1):
    lid = f"L{4000 + i}"
    enc = encounter_rows[i - 1][0]
    pid = encounter_rows[i - 1][1]
    test = lab_tests[(i - 1) % len(lab_tests)]
    low, high = test[3], test[4]
    value = round(low + ((i - 1) % (high - low + 1)) * 0.75, 1)
    result_date = datetime.strptime(encounter_rows[i - 1][2], "%Y-%m-%d") + timedelta(days=1)
    ingest = datetime(2026, 6, 11, 12, 0, 0) + timedelta(seconds=i)
    lab_rows.append([
        lid,
        pid,
        enc,
        test[0],
        test[1],
        str(value),
        test[2],
        result_date.strftime("%Y-%m-%d"),
        ingest.strftime("%Y-%m-%d %H:%M:%S"),
    ])

pharmacy_rows = []
for i in range(1, num_rows + 1):
    rx = f"RX{5000 + i}"
    pid = patient_rows[i - 1][0]
    med = medications[(i - 1) % len(medications)]
    dose = "10 mg daily" if i % 3 == 0 else "5 mg daily" if i % 3 == 1 else "500 mg twice daily"
    date = base_date + timedelta(days=(i - 1) % 180)
    doc = doctors[(i - 1) % len(doctors)]
    ingest = datetime(2026, 6, 11, 13, 0, 0) + timedelta(seconds=i)
    pharmacy_rows.append([
        rx,
        pid,
        med,
        dose,
        date.strftime("%Y-%m-%d"),
        doc,
        ingest.strftime("%Y-%m-%d %H:%M:%S"),
    ])

claim_rows = []
for i in range(1, num_rows + 1):
    cid = f"C{6000 + i}"
    pid = patient_rows[i - 1][0]
    ins = f"INS-{chr(65 + ((i - 1) % 26))}{100 + ((i - 1) % 900)}"
    amount = round(500 + ((i - 1) % 100) * 250.0, 2)
    status = claim_statuses[(i - 1) % len(claim_statuses)]
    date = base_date + timedelta(days=(i - 1) % 180)
    ingest = datetime(2026, 6, 11, 14, 0, 0) + timedelta(seconds=i)
    claim_rows.append([
        cid,
        pid,
        ins,
        f"{amount:.2f}",
        status,
        date.strftime("%Y-%m-%d"),
        ingest.strftime("%Y-%m-%d %H:%M:%S"),
    ])

files = [
    ("patient_master_1000.csv", [
        "patient_id", "medical_record_number", "patient_first_name", "patient_last_name", "dob", "gender", "ssn", "phone_number",
        "email_address", "address_line1", "city", "state", "zip_code", "ingestion_timestamp"
    ], patient_rows),
    ("patient_encounter_1000.csv", [
        "encounter_id", "patient_id", "admission_date", "discharge_date", "encounter_type", "attending_physician", "hospital_id", "diagnosis_code", "ingestion_timestamp"
    ], encounter_rows),
    ("lab_results_1000.csv", [
        "lab_result_id", "patient_id", "encounter_id", "test_code", "test_name", "result_value", "result_unit", "result_date", "ingestion_timestamp"
    ], lab_rows),
    ("pharmacy_orders_1000.csv", [
        "prescription_id", "patient_id", "medication_name", "dosage", "prescription_date", "prescribing_physician", "ingestion_timestamp"
    ], pharmacy_rows),
    ("claims_1000.csv", [
        "claim_id", "patient_id", "insurance_id", "claim_amount", "claim_status", "claim_date", "ingestion_timestamp"
    ], claim_rows),
]

for file_name, header, rows in files:
    path = OUT_DIR / file_name
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
    print(f"Wrote {path} ({len(rows)} rows)")
