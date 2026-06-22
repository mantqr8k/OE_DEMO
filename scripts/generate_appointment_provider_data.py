import csv
import random
from datetime import datetime, timedelta
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / "data"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Provider data
specialties = [
    "Cardiology", "Neurology", "Orthopedics", "Internal Medicine",
    "Pediatrics", "Emergency Medicine", "Oncology", "Pulmonology"
]

hospitals = ["H001", "H002", "H003", "H004", "H005"]

first_names = [
    "Alex", "Taylor", "Jordan", "Morgan", "Casey", "Jamie", "Riley", "Avery", "Cameron", "Drew",
    "Ryan", "Sydney", "Parker", "Quinn", "Blake", "Harper", "Reese", "Skyler", "Rowan", "Devon"
]

last_names = [
    "Anderson", "Brooks", "Carter", "Diaz", "Edwards", "Fisher", "Gonzalez", "Harris", "Ibrahim", "Jackson",
    "Kim", "Lewis", "Mills", "Nelson", "Owens", "Patterson", "Quinn", "Reynolds", "Stewart", "Turner"
]

appointment_statuses = ["SCHEDULED", "COMPLETED", "NO_SHOW", "CANCELLED", "RESCHEDULED"]

base_date = datetime(2026, 1, 1)

def generate_provider_data(num_providers=500):
    """Generate provider master data with intentional quality issues"""
    providers = []
    
    for i in range(1, num_providers + 1):
        provider_id = f"PROV{10000 + i}"
        provider_name = f"Dr. {random.choice(first_names)} {random.choice(last_names)}"
        specialty = random.choice(specialties)
        hospital_id = random.choice(hospitals)
        license_number = f"LIC{100000 + i:06d}"
        
        # Inject quality issues
        if i % 50 == 0:  # 1% expired licenses
            license_expiry_date = (base_date - timedelta(days=random.randint(1, 365))).strftime("%Y-%m-%d")
        else:
            license_expiry_date = (base_date + timedelta(days=random.randint(1, 730))).strftime("%Y-%m-%d")
        
        # Occasionally null provider_id for data quality testing
        if i % 500 == 0:
            provider_id = None
        
        providers.append({
            'provider_id': provider_id,
            'provider_name': provider_name,
            'specialty': specialty,
            'hospital_id': hospital_id,
            'license_number': license_number,
            'license_expiry_date': license_expiry_date,
            'ingestion_timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return providers


def generate_appointment_data(num_appointments=30000, num_patients=5000, num_providers=500):
    """Generate appointment data with intentional quality issues"""
    appointments = []
    
    for i in range(1, num_appointments + 1):
        appointment_id = f"APT{100000 + i}"
        patient_id = f"P{2000 + random.randint(1, num_patients)}"
        provider_id = f"PROV{10000 + random.randint(1, num_providers)}"
        hospital_id = random.choice(hospitals)
        
        appointment_date = (base_date + timedelta(days=random.randint(0, 180))).strftime("%Y-%m-%d")
        scheduled_time = f"{random.randint(8, 17):02d}:{random.randint(0, 59):02d}:00"
        
        # Inject quality issues
        appointment_status = random.choice(appointment_statuses)
        
        # For quality testing: some have invalid status
        if i % 1000 == 0:
            appointment_status = "INVALID_STATUS"
        
        # For completed/no-show, generate actual start time
        if appointment_status in ["COMPLETED", "NO_SHOW", "CANCELLED"]:
            scheduled_dt = datetime.strptime(f"{appointment_date} {scheduled_time}", "%Y-%m-%d %H:%M:%S")
            
            # Quality issue: actual start before scheduled (occasional)
            if i % 500 == 0:
                actual_start_time = (scheduled_dt - timedelta(minutes=random.randint(5, 30))).strftime("%H:%M:%S")
            else:
                actual_start_time = (scheduled_dt + timedelta(minutes=random.randint(0, 120))).strftime("%H:%M:%S")
            
            # Calculate wait time
            actual_dt = datetime.strptime(f"{appointment_date} {actual_start_time}", "%Y-%m-%d %H:%M:%S")
            wait_minutes = int((actual_dt - scheduled_dt).total_seconds() / 60)
            
            # Quality issue: wait time exceeding 240 minutes (occasional)
            if i % 800 == 0:
                wait_minutes = random.randint(250, 480)
        else:
            actual_start_time = None
            wait_minutes = None
        
        cancellation_flag = 1 if appointment_status == "CANCELLED" else 0
        no_show_flag = 1 if appointment_status == "NO_SHOW" else 0
        
        # Occasionally null appointment_id for data quality testing
        if i % 3000 == 0:
            appointment_id = None
        
        appointments.append({
            'appointment_id': appointment_id,
            'patient_id': patient_id,
            'provider_id': provider_id,
            'hospital_id': hospital_id,
            'appointment_date': appointment_date,
            'appointment_status': appointment_status,
            'scheduled_time': scheduled_time,
            'actual_start_time': actual_start_time,
            'wait_time_minutes': wait_minutes,
            'cancellation_flag': cancellation_flag,
            'no_show_flag': no_show_flag,
            'ingestion_timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return appointments


def write_csv(filename, rows, fieldnames):
    """Write data to CSV file"""
    filepath = OUT_DIR / filename
    with open(filepath, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Generated {len(rows)} rows in {filepath}")


# Generate provider data
print("Generating provider master data...")
providers = generate_provider_data(500)
provider_fieldnames = [
    'provider_id', 'provider_name', 'specialty', 'hospital_id',
    'license_number', 'license_expiry_date', 'ingestion_timestamp'
]
write_csv('provider_master_1000.csv', providers, provider_fieldnames)

# Generate a second version with full 500 records
write_csv('provider_master.csv', providers, provider_fieldnames)

# Generate appointment data
print("Generating appointment data...")
appointments = generate_appointment_data(30000, 5000, 500)
appointment_fieldnames = [
    'appointment_id', 'patient_id', 'provider_id', 'hospital_id',
    'appointment_date', 'appointment_status', 'scheduled_time',
    'actual_start_time', 'wait_time_minutes', 'cancellation_flag',
    'no_show_flag', 'ingestion_timestamp'
]
write_csv('appointments.csv', appointments, appointment_fieldnames)

# Generate 1000-row version for testing
appointments_1000 = appointments[:1000]
write_csv('appointments_1000.csv', appointments_1000, appointment_fieldnames)

print("Data generation complete!")
