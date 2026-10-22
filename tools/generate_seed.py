"""Generate ZutLib demonstration seed data (SRS section 7).

Writes assets/seed/*.json and assets/papers/*.pdf. Every date is written relative to
SEED_ANCHOR; the app shifts all dates so the anchor equals "now" at first launch or reset,
which keeps due dates and dashboards meaningful whenever the demo is run.

Usage: python tools/generate_seed.py   (needs: pip install reportlab)
"""

import hashlib
import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas

from seed_content import CONTENT

ROOT = Path(__file__).resolve().parent.parent
SEED_DIR = ROOT / "assets" / "seed"
PAPER_DIR = ROOT / "assets" / "papers"
SEED_ANCHOR = datetime(2026, 10, 20, 8, 0, tzinfo=timezone.utc)
PASSWORD = "demo1234"
rng = random.Random(2300339)


def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def at(days=0, hours=0):
    return iso(SEED_ANCHOR + timedelta(days=days, hours=hours))


def password_hash(pw):
    # Mock hash only (SRS 6: passwordHash (mock)); mirrors lib/core/hashing.dart.
    return hashlib.sha256(f"zutlib-demo-salt:{pw}".encode()).hexdigest()


# ---------------------------------------------------------------- tenants

tenants = [
    {"id": "t_zut", "name": "Zambia University College of Technology", "shortCode": "ZUT",
     "themeColour": "#1B5E20", "logoAsset": None, "createdAt": at(-400)},
    {"id": "t_nbt", "name": "Northbridge Technical College", "shortCode": "NBT",
     "themeColour": "#0D47A1", "logoAsset": None, "createdAt": at(-200)},
]

departments = [
    {"id": "d_zut_ict", "tenantId": "t_zut", "name": "Information and Communication Technology", "code": "ICT"},
    {"id": "d_zut_bus", "tenantId": "t_zut", "name": "Business Studies", "code": "BUS"},
    {"id": "d_zut_eng", "tenantId": "t_zut", "name": "Engineering", "code": "ENG"},
    {"id": "d_nbt_cmp", "tenantId": "t_nbt", "name": "Computing", "code": "CMP"},
    {"id": "d_nbt_een", "tenantId": "t_nbt", "name": "Electrical Engineering", "code": "EEN"},
]

courses = [
    {"id": "c_ict1101", "tenantId": "t_zut", "departmentId": "d_zut_ict", "code": "ICT 1101", "name": "Introduction to Programming", "yearLevel": 1},
    {"id": "c_ict2201", "tenantId": "t_zut", "departmentId": "d_zut_ict", "code": "ICT 2201", "name": "Database Systems", "yearLevel": 2},
    {"id": "c_ict2205", "tenantId": "t_zut", "departmentId": "d_zut_ict", "code": "ICT 2205", "name": "Data Structures and Algorithms", "yearLevel": 2},
    {"id": "c_ict3301", "tenantId": "t_zut", "departmentId": "d_zut_ict", "code": "ICT 3301", "name": "Computer Networks", "yearLevel": 3},
    {"id": "c_bus1102", "tenantId": "t_zut", "departmentId": "d_zut_bus", "code": "BUS 1102", "name": "Principles of Accounting", "yearLevel": 1},
    {"id": "c_cmp110", "tenantId": "t_nbt", "departmentId": "d_nbt_cmp", "code": "CMP 110", "name": "Programming Fundamentals", "yearLevel": 1},
    {"id": "c_cmp210", "tenantId": "t_nbt", "departmentId": "d_nbt_cmp", "code": "CMP 210", "name": "Web Development", "yearLevel": 2},
    {"id": "c_een120", "tenantId": "t_nbt", "departmentId": "d_nbt_een", "code": "EEN 120", "name": "Circuit Theory", "yearLevel": 1},
]
course_by_code = {c["code"]: c for c in courses}

# ---------------------------------------------------------------- users


def user(uid, tenant, name, email, role, **extra):
    base = {
        "id": uid, "tenantId": tenant, "fullName": name, "email": email,
        "passwordHash": password_hash(PASSWORD), "role": role, "studentNumber": None,
        "departmentId": None, "yearOfStudy": None, "enrolledCourseIds": [], "examDates": {},
        "studyTimePreferences": [], "active": True, "roleGrantedAt": at(-300),
        "profileComplete": role != "student", "notificationPrefs": {},
    }
    base.update(extra)
    return base


users = [
    user("u_zut_chanda", "t_zut", "Chanda Mwila", "student@zut.demo", "student",
         studentNumber="2300101", departmentId="d_zut_ict", yearOfStudy=2,
         enrolledCourseIds=["c_ict2201", "c_ict2205", "c_ict1101"],
         examDates={"c_ict2201": at(9), "c_ict2205": at(16), "c_ict1101": at(23)},
         studyTimePreferences=["18:00", "20:00"], profileComplete=True, roleGrantedAt=at(-120)),
    user("u_zut_natasha", "t_zut", "Natasha Banda", "student2@zut.demo", "student",
         studentNumber="2300102", departmentId="d_zut_ict", yearOfStudy=2, roleGrantedAt=at(-120)),
    user("u_zut_mary", "t_zut", "Mary Phiri", "librarian@zut.demo", "librarian", roleGrantedAt=at(-280)),
    user("u_zut_joseph", "t_zut", "Joseph Tembo", "admin@zut.demo", "institutionAdmin", roleGrantedAt=at(-390)),
    user("u_nbt_mutale", "t_nbt", "Mutale Zulu", "student@northbridge.demo", "student",
         studentNumber="NB24017", departmentId="d_nbt_cmp", yearOfStudy=1,
         enrolledCourseIds=["c_cmp110", "c_cmp210"],
         examDates={"c_cmp110": at(12), "c_cmp210": at(20)},
         studyTimePreferences=["07:00", "19:00"], profileComplete=True, roleGrantedAt=at(-90)),
    user("u_nbt_grace", "t_nbt", "Grace Lungu", "librarian@northbridge.demo", "librarian", roleGrantedAt=at(-190)),
    user("u_platform", "platform", "Platform Admin", "platform@zutlib.demo", "platformAdmin", roleGrantedAt=at(-400)),
]

# Additional fictional students so lists and dashboards have realistic volume (~30 users).
extra_names = [
    "Bwalya Musonda", "Mwansa Kabwe", "Thandiwe Daka", "Kelvin Chileshe", "Ruth Sakala",
    "Emmanuel Ngoma", "Precious Mulenga", "Brian Mumba", "Esther Lungu", "Moses Kunda",
    "Faith Chanda", "Daniel Siame", "Mercy Zimba", "Joshua Mwale", "Grace Nkonde",
    "Patrick Chola", "Agnes Tembo", "Victor Simwanza", "Lydia Mbewe", "Samuel Kasonde",
]
for i, name in enumerate(extra_names):
    is_zut = i < 14
    tenant = "t_zut" if is_zut else "t_nbt"
    pool = ["c_ict2201", "c_ict2205", "c_ict1101", "c_ict3301", "c_bus1102"] if is_zut else ["c_cmp110", "c_cmp210", "c_een120"]
    enrolled = rng.sample(pool, 2)
    first = name.split()[0].lower()
    domain = "zut.demo" if is_zut else "northbridge.demo"
    users.append(user(
        f"u_{'zut' if is_zut else 'nbt'}_s{i:02d}", tenant, name, f"{first}.{i:02d}@{domain}", "student",
        studentNumber=(f"23{i:05d}" if is_zut else f"NB24{i:03d}"),
        departmentId=("d_zut_ict" if is_zut else "d_nbt_cmp"), yearOfStudy=rng.randint(1, 3),
        enrolledCourseIds=enrolled, examDates={c: at(rng.randint(8, 30)) for c in enrolled},
        studyTimePreferences=["18:00"], profileComplete=True, roleGrantedAt=at(-rng.randint(30, 200)),
    ))
# One deactivated account for the admin user list (FR-ADM-01).
users[-1]["active"] = False

# ---------------------------------------------------------------- resources

PAPER_TYPES = {"final": "Final examination", "mid": "Mid-semester test", "supp": "Supplementary",
               "assignment": "Assignment", "notes": "Notes"}

resource_specs = [
    # code, year, semester, type, lecturer, duration, marks, memo
    ("ICT 1101", 2021, 1, "final", "Mr B. Kalaba", 180, 100, False),
    ("ICT 1101", 2023, 1, "final", "Mr B. Kalaba", 180, 100, True),
    ("ICT 1101", 2024, 1, "mid", "Ms C. Ngulube", 90, 50, False),
    ("ICT 2201", 2019, 2, "final", "Dr M. Sinkala", 180, 100, False),
    ("ICT 2201", 2021, 2, "supp", "Dr M. Sinkala", 180, 100, False),
    ("ICT 2201", 2023, 2, "final", "Dr M. Sinkala", 180, 100, True),
    ("ICT 2201", 2024, 2, "final", "Mr K. Mwape", 180, 100, True),
    ("ICT 2205", 2020, 1, "final", "Mrs J. Chibwe", 180, 100, False),
    ("ICT 2205", 2022, 1, "final", "Mrs J. Chibwe", 180, 100, True),
    ("ICT 2205", 2025, 1, "mid", "Mrs J. Chibwe", 90, 50, False),
    ("ICT 3301", 2022, 2, "final", "Mr L. Mutale", 180, 100, False),
    ("ICT 3301", 2024, 2, "final", "Mr L. Mutale", 180, 100, False),
    ("BUS 1102", 2021, 1, "final", "Mrs P. Nyirenda", 180, 100, False),
    ("BUS 1102", 2023, 1, "assignment", "Mrs P. Nyirenda", None, 40, False),
    ("CMP 110", 2020, 1, "final", "Mr T. Hamoonga", 180, 100, False),
    ("CMP 110", 2023, 1, "final", "Mr T. Hamoonga", 180, 100, True),
    ("CMP 110", 2024, 2, "mid", "Ms R. Phiri", 90, 50, False),
    ("CMP 210", 2022, 2, "final", "Mr D. Banda", 180, 100, False),
    ("CMP 210", 2025, 1, "notes", "Mr D. Banda", None, None, False),
    ("EEN 120", 2023, 1, "final", "Eng. S. Mulenga", 180, 100, False),
]

OTHER_TOPICS = {
    "ICT 3301": ["OSI model", "IP addressing", "Routing", "TCP and UDP", "Network security"],
    "BUS 1102": ["Double entry", "Trial balance", "Final accounts", "Depreciation"],
    "CMP 210": ["HTML", "CSS layout", "JavaScript", "HTTP"],
    "EEN 120": ["Ohm's law", "Kirchhoff's laws", "AC circuits", "Thevenin's theorem"],
}

resources = []
for idx, (code, year, sem, ptype, lect, dur, marks, memo) in enumerate(resource_specs):
    course = course_by_code[code]
    rid = f"r_{code.replace(' ', '').lower()}_{year}_{ptype}"
    all_topics = list(CONTENT[code].keys()) if code in CONTENT else OTHER_TOPICS[code]
    topics = sorted(rng.sample(all_topics, min(len(all_topics), rng.randint(3, 4))))
    resources.append({
        "id": rid, "tenantId": course["tenantId"], "courseId": course["id"],
        "title": f"{code} {course['name']} - {PAPER_TYPES[ptype]} {year}",
        "academicYear": year, "semester": sem, "paperType": ptype, "lecturer": lect,
        "durationMinutes": dur, "totalMarks": marks, "topics": topics,
        "fileAsset": f"assets/papers/{rid}.pdf", "hasMemo": memo, "summary": None,
        "archived": False, "uploadedBy": "u_zut_mary" if course["tenantId"] == "t_zut" else "u_nbt_grace",
        "uploadedAt": at(-rng.randint(20, 300)),
    })

# ---------------------------------------------------------------- questions and flashcards

questions = []
flashcards = []
resources_by_course = {}
for r in resources:
    resources_by_course.setdefault(r["courseId"], []).append(r)


def source_for(course_id, topic):
    pool = resources_by_course[course_id]
    matching = [r for r in pool if topic in r["topics"]]
    return rng.choice(matching or pool)["id"]


for code, topics in CONTENT.items():
    course = course_by_code[code]
    n = 0
    for topic, items in topics.items():
        for text, options, correct, expl in items["mcq"]:
            n += 1
            src = source_for(course["id"], topic)
            questions.append({
                "id": f"q_{course['id']}_{n:03d}", "tenantId": course["tenantId"], "courseId": course["id"],
                "sourceResourceId": src, "topic": topic, "type": "multipleChoice", "text": text,
                "options": options, "correctAnswer": options[correct], "acceptedKeywords": [],
                "explanation": expl,
            })
            # Derived true/false: half the statements are true, half use a wrong option.
            n += 1
            use_true = n % 4 == 0
            shown = options[correct] if use_true else options[(correct + 1) % len(options)]
            if text.endswith("?"):
                tf_text = f"{text} Proposed answer: {shown}. Is this correct?"
            else:
                stem = text.rstrip(":").rstrip()
                first = shown.split(" ")[0]
                lower = first.isalpha() and (len(first) == 1 or not first.isupper())
                value = shown[0].lower() + shown[1:] if lower else shown
                if stem.endswith((" a", " an")):
                    stem = stem.rsplit(" ", 1)[0] + (" an" if value[0].lower() in "aeiou" else " a")
                tf_text = f"True or false: {stem} {value}."
            questions.append({
                "id": f"q_{course['id']}_{n:03d}", "tenantId": course["tenantId"], "courseId": course["id"],
                "sourceResourceId": src, "topic": topic, "type": "trueFalse",
                "text": tf_text, "options": ["True", "False"],
                "correctAnswer": "True" if use_true else "False", "acceptedKeywords": [],
                "explanation": f"The correct answer is: {options[correct]}. {expl}",
            })
        for text, answer, keywords, expl in items["short"]:
            n += 1
            questions.append({
                "id": f"q_{course['id']}_{n:03d}", "tenantId": course["tenantId"], "courseId": course["id"],
                "sourceResourceId": source_for(course["id"], topic), "topic": topic, "type": "shortAnswer",
                "text": text, "options": [], "correctAnswer": answer, "acceptedKeywords": keywords,
                "explanation": expl,
            })
        for i, (front, back) in enumerate(items["cards"]):
            flashcards.append({
                "id": f"f_{course['id']}_{len(flashcards):03d}", "tenantId": course["tenantId"],
                "courseId": course["id"], "front": front, "back": back, "topic": topic,
            })

# ---------------------------------------------------------------- summaries (FR-SSA-07)

qs_by_resource = {}
for q in questions:
    qs_by_resource.setdefault(q["sourceResourceId"], []).append(q)

for r in resources:
    code = next(c["code"] for c in courses if c["id"] == r["courseId"])
    if code not in CONTENT or r["paperType"] == "notes":
        continue
    total = r["totalMarks"] or 100
    sections = len(r["topics"])
    base = total // sections
    dist = [{"section": f"Question {i + 1}: {t}", "marks": base + (total - base * sections if i == 0 else 0)}
            for i, t in enumerate(r["topics"])]
    types = sorted({q["type"] for q in qs_by_resource.get(r["id"], [])}) or ["multipleChoice"]
    type_names = {"multipleChoice": "Multiple choice", "trueFalse": "True/false", "shortAnswer": "Short answer"}
    r["summary"] = {
        "overview": f"{len(r['topics'])} sections covering {', '.join(r['topics'][:-1])} and {r['topics'][-1]}. "
                    f"Answer all questions; {r['durationMinutes'] or 'no'} minutes.",
        "topics": r["topics"],
        "questionTypes": [type_names[t] for t in types] + ["Structured / essay"],
        "markDistribution": dist,
    }

# ---------------------------------------------------------------- physical copies

copies = []
for r in resources:
    if r["paperType"] == "notes":
        continue
    for c in range(rng.randint(1, 3)):
        copies.append({
            "id": f"pc_{r['id'][2:]}_{c + 1}", "tenantId": r["tenantId"], "resourceId": r["id"],
            "copyNumber": c + 1, "shelfLocation": f"{'AB'[c % 2]}{rng.randint(1, 6)}-{rng.randint(1, 12):02d}",
            "status": "available",
        })
# Demo step 2 needs ICT 2201 2023 to have at least two copies.
ict2201_2023 = [c for c in copies if c["resourceId"] == "r_ict2201_2023_final"]
while len(ict2201_2023) < 2:
    n = len(ict2201_2023) + 1
    c = {"id": f"pc_ict2201_2023_final_{n}", "tenantId": "t_zut", "resourceId": "r_ict2201_2023_final",
         "copyNumber": n, "shelfLocation": f"B2-{n:02d}", "status": "available"}
    copies.append(c)
    ict2201_2023.append(c)

# ---------------------------------------------------------------- loans (SRS 7.3)


def free_copy(resource_id, status):
    for c in copies:
        if c["resourceId"] == resource_id and c["status"] == "available":
            c["status"] = status
            return c["id"]
    raise SystemExit(f"no free copy for {resource_id}")


def token():
    return "".join(rng.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))


loans = []


def loan(lid, tenant, student, resource, status, req_day, approver=None, appr_day=None, coll_day=None,
         ret_day=None, reason=None):
    copy_status = {"approved": "reserved", "collected": "onLoan", "overdue": "onLoan"}.get(status)
    copy_id = free_copy(resource, copy_status) if copy_status else None
    if status == "returned":
        copy_id = next(c["id"] for c in copies if c["resourceId"] == resource)
    loans.append({
        "id": lid, "tenantId": tenant, "studentId": student, "resourceId": resource, "copyId": copy_id,
        "status": status, "requestedAt": at(req_day), "approvedBy": approver,
        "approvedAt": at(appr_day) if appr_day is not None else None,
        "qrToken": token() if appr_day is not None else None, "qrUsed": coll_day is not None,
        "collectedAt": at(coll_day) if coll_day is not None else None,
        "dueAt": at(coll_day + 7) if coll_day is not None else None,
        "returnedAt": at(ret_day) if ret_day is not None else None,
        "rejectionReason": reason, "renewalCount": 0, "renewalRequested": False,
        "notifiedDueSoon": False,
    })


M = "u_zut_mary"
loan("l_zut_01", "t_zut", "u_zut_natasha", "r_ict2205_2022_final", "requested", -0.2)
loan("l_zut_02", "t_zut", "u_zut_s00", "r_ict3301_2024_final", "approved", -1, M, -0.5)
loan("l_zut_03", "t_zut", "u_zut_chanda", "r_ict2205_2020_final", "collected", -3, M, -2.9, -2.5)
loan("l_zut_04", "t_zut", "u_zut_s01", "r_ict1101_2023_final", "collected", -5, M, -4.8, -4.5)
loan("l_zut_05", "t_zut", "u_zut_s02", "r_ict2201_2019_final", "overdue", -12, M, -11.8, -11)
loan("l_zut_06", "t_zut", "u_zut_chanda", "r_ict2201_2024_final", "returned", -30, M, -29.8, -29, ret_day=-23)
loan("l_zut_07", "t_zut", "u_zut_s03", "r_bus1102_2021_final", "returned", -25, M, -24.8, -24, ret_day=-19)
loan("l_zut_08", "t_zut", "u_zut_s04", "r_ict2201_2021_supp", "returned", -18, M, -17.9, -17, ret_day=-12)
loan("l_zut_09", "t_zut", "u_zut_s05", "r_ict3301_2022_final", "rejected", -8, reason="Copy is being rebound; request again next week.")
loan("l_nbt_01", "t_nbt", "u_nbt_s14", "r_cmp110_2023_final", "requested", -0.3)
loan("l_nbt_02", "t_nbt", "u_nbt_mutale", "r_cmp210_2022_final", "collected", -2, "u_nbt_grace", -1.9, -1.5)
loan("l_nbt_03", "t_nbt", "u_nbt_s15", "r_een120_2023_final", "returned", -20, "u_nbt_grace", -19.8, -19, ret_day=-13)

# ---------------------------------------------------------------- usage events and quiz attempts

events = []
search_terms = ["ICT 2201", "database", "normalisation", "ICT 2205", "sorting", "SQL", "ICT 1101",
                "networks", "accounting", "trees", "linked list", "2023"]
unmet_terms = ["ICT 4402", "operating systems", "statistics", "ICT 3310 software engineering",
               "operating systems", "discrete maths", "statistics", "operating systems"]
zut_resources = [r for r in resources if r["tenantId"] == "t_zut"]
nbt_resources = [r for r in resources if r["tenantId"] == "t_nbt"]
eid = 0


def event(tenant, etype, day, ref=None, term=None):
    global eid
    eid += 1
    events.append({"id": f"e_{eid:04d}", "tenantId": tenant, "type": etype, "refId": ref, "term": term,
                   "createdAt": at(day, rng.randint(8, 20))})


for day in range(-14, 0):
    for _ in range(rng.randint(3, 7)):
        event("t_zut", "search", day, term=rng.choice(search_terms))
    for _ in range(rng.randint(0, 2)):
        event("t_zut", "unmetSearch", day, term=rng.choice(unmet_terms))
    weights = [5 if "2201" in r["id"] or "2205" in r["id"] else 1 for r in zut_resources]
    for _ in range(rng.randint(4, 9)):
        event("t_zut", "view", day, ref=rng.choices(zut_resources, weights)[0]["id"])
    for _ in range(rng.randint(1, 3)):
        event("t_nbt", "search", day, term=rng.choice(["CMP 110", "HTML", "circuits", "loops"]))
        event("t_nbt", "view", day, ref=rng.choice(nbt_resources)["id"])
    if rng.random() < 0.3:
        event("t_nbt", "unmetSearch", day, term=rng.choice(["database", "physics"]))
for l in loans:
    event(l["tenantId"], "loan", (datetime.strptime(l["requestedAt"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc) - SEED_ANCHOR).days, ref=l["id"])

attempts = []


def attempt(aid, tenant, student, course_id, day, topic_bias):
    pool = [q for q in questions if q["courseId"] == course_id]
    chosen = rng.sample(pool, 10)
    answers, topic_scores, correct_total = {}, {}, 0
    for q in chosen:
        ok = rng.random() < topic_bias.get(q["topic"], 0.75)
        answers[q["id"]] = q["correctAnswer"] if ok else "(wrong)"
        t = topic_scores.setdefault(q["topic"], {"correct": 0, "total": 0})
        t["total"] += 1
        t["correct"] += 1 if ok else 0
        correct_total += 1 if ok else 0
    start = SEED_ANCHOR + timedelta(days=day, hours=rng.randint(9, 20))
    attempts.append({
        "id": aid, "tenantId": tenant, "studentId": student, "courseId": course_id,
        "questionIds": [q["id"] for q in chosen], "answers": answers,
        "score": round(correct_total / len(chosen) * 100), "topicScores": topic_scores,
        "startedAt": iso(start), "finishedAt": iso(start + timedelta(minutes=rng.randint(6, 14))),
    })
    event(tenant, "quiz", day, ref=aid)


# Chanda is weak on Normalisation and Trees so FR-SSA-04 weighting is visible in the demo.
bias_2201 = {"Normalisation": 0.35, "Transactions": 0.55}
bias_2205 = {"Trees": 0.4, "Sorting": 0.6}
for i, day in enumerate([-13, -10, -7, -4, -2]):
    attempt(f"a_zut_c2201_{i}", "t_zut", "u_zut_chanda", "c_ict2201", day, {k: v + i * 0.06 for k, v in bias_2201.items()})
for i, day in enumerate([-12, -8, -3]):
    attempt(f"a_zut_c2205_{i}", "t_zut", "u_zut_chanda", "c_ict2205", day, {k: v + i * 0.05 for k, v in bias_2205.items()})
for i, day in enumerate([-9, -5, -1]):
    attempt(f"a_zut_o_{i}", "t_zut", f"u_zut_s0{i + 1}", "c_ict2201", day, {})
for i, day in enumerate([-6, -2]):
    attempt(f"a_nbt_m_{i}", "t_nbt", "u_nbt_mutale", "c_cmp110", day, {"Iteration": 0.5})

notifications = [
    {"id": "n_seed_1", "tenantId": "t_zut", "userId": "u_zut_chanda", "category": "loan",
     "title": "Copy collected", "body": "ICT 2205 Final examination 2020 is due back in 4 days.",
     "targetRoute": "loan:l_zut_03", "read": True, "createdAt": at(-2.5)},
    {"id": "n_seed_2", "tenantId": "t_zut", "userId": "u_zut_chanda", "category": "newResource",
     "title": "New paper for ICT 2201", "body": "ICT 2201 Database Systems - Final examination 2024 is now available.",
     "targetRoute": "resource:r_ict2201_2024_final", "read": False, "createdAt": at(-6)},
    {"id": "n_seed_3", "tenantId": "t_zut", "userId": "u_zut_s02", "category": "loan",
     "title": "Loan overdue", "body": "ICT 2201 Final examination 2019 was due 4 days ago. Return it to the library.",
     "targetRoute": "loan:l_zut_05", "read": False, "createdAt": at(-4)},
]

feedback = [
    {"id": "fb_1", "tenantId": "t_zut", "userId": "u_zut_s03", "message": "Please add ICT 3310 Software Engineering past papers.", "createdAt": at(-5)},
    {"id": "fb_2", "tenantId": "t_zut", "userId": "u_zut_s07", "message": "The QR collection was quick. Could loans be 10 days during exams?", "createdAt": at(-2)},
]

# ---------------------------------------------------------------- PDFs


def draw_paper(r):
    course = next(c for c in courses if c["id"] == r["courseId"])
    tenant = next(t for t in tenants if t["id"] == r["tenantId"])
    path = PAPER_DIR / f"{r['id']}.pdf"
    pdf = canvas.Canvas(str(path), pagesize=A4)
    width, height = A4
    pdf.setTitle(r["title"])

    def header(page):
        pdf.setFont("Helvetica-Bold", 9)
        pdf.drawString(20 * mm, height - 12 * mm, "SAMPLE - FICTIONAL DEMONSTRATION PAPER - NOT AN OFFICIAL EXAMINATION")
        pdf.drawRightString(width - 20 * mm, height - 12 * mm, f"Page {page}")

    header(1)
    y = height - 30 * mm
    for text, size in [(tenant["name"].upper(), 14), (f"{course['code']} {course['name']}", 13),
                       (f"{PAPER_TYPES[r['paperType']]} - Academic year {r['academicYear']}, semester {r['semester']}", 11)]:
        pdf.setFont("Helvetica-Bold", size)
        pdf.drawCentredString(width / 2, y, text)
        y -= 9 * mm
    pdf.setFont("Helvetica", 10)
    meta = []
    if r["durationMinutes"]:
        meta.append(f"Time allowed: {r['durationMinutes'] // 60} hours" if r["durationMinutes"] >= 60 else f"Time allowed: {r['durationMinutes']} minutes")
    if r["totalMarks"]:
        meta.append(f"Total marks: {r['totalMarks']}")
    meta.append(f"Lecturer: {r['lecturer']}")
    pdf.drawCentredString(width / 2, y, "    ".join(meta))
    y -= 12 * mm
    pdf.setFont("Helvetica-Oblique", 10)
    pdf.drawString(20 * mm, y, "Instructions: answer ALL questions. Write clearly. Show all working.")
    y -= 12 * mm

    page = 1
    pool = [q for q in questions if q["courseId"] == r["courseId"] and q["type"] != "trueFalse"]
    for i, topic in enumerate(r["topics"]):
        items = [q for q in pool if q["topic"] == topic][:4]
        pdf.setFont("Helvetica-Bold", 11)
        pdf.drawString(20 * mm, y, f"Question {i + 1}: {topic}")
        y -= 7 * mm
        pdf.setFont("Helvetica", 10)
        lines = [f"({chr(97 + j)}) {q['text']}" for j, q in enumerate(items)] or [
            f"(a) Explain the key ideas of {topic} with examples.",
            f"(b) Apply {topic} to a practical problem of your choice.",
        ]
        for line in lines:
            while line:
                chunk, line = line[:95], line[95:]
                pdf.drawString(25 * mm, y, chunk)
                y -= 6 * mm
            if y < 30 * mm:
                pdf.showPage()
                page += 1
                header(page)
                y = height - 25 * mm
                pdf.setFont("Helvetica", 10)
        y -= 6 * mm
    pdf.setFont("Helvetica-Oblique", 9)
    pdf.drawCentredString(width / 2, 15 * mm, "END OF PAPER - generated sample for the ZutLib prototype")
    pdf.save()


def main():
    SEED_DIR.mkdir(parents=True, exist_ok=True)
    PAPER_DIR.mkdir(parents=True, exist_ok=True)
    for old in PAPER_DIR.glob("*.pdf"):
        old.unlink()
    for r in resources:
        draw_paper(r)
    data = {
        "meta": {"seedAnchor": iso(SEED_ANCHOR), "version": 1},
        "tenants": tenants, "departments": departments, "courses": courses, "users": users,
        "resources": resources, "copies": copies, "loans": loans, "questions": questions,
        "flashcards": flashcards, "quizAttempts": attempts, "usageEvents": events,
        "notifications": notifications, "feedback": feedback,
    }
    for name, rows in data.items():
        (SEED_DIR / f"{name}.json").write_text(json.dumps(rows, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{len(tenants)} tenants, {len(users)} users, {len(resources)} resources, {len(copies)} copies, "
          f"{len(loans)} loans, {len(questions)} questions, {len(flashcards)} flashcards, "
          f"{len(attempts)} attempts, {len(events)} events")


if __name__ == "__main__":
    main()
