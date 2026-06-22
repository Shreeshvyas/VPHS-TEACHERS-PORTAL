from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from core.models import Student, Task, Attendance, Grade, BehaviorRemark, Notice
from django.utils import timezone
import datetime
import random

class Command(BaseCommand):
    help = 'Seeds the database with a default teacher user, students, tasks, attendances, grades, behavior remarks, and notices.'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding database with professional portal data...')

        # 1. Create Teacher (User)
        username = 'teacher'
        email = 'teacher@school.com'
        password = 'password123'
        
        user, created = User.objects.get_or_create(username=username, defaults={
            'email': email,
            'first_name': 'Sarah',
            'last_name': 'Conner'
        })
        
        if created:
            user.set_password(password)
            user.save()
            self.stdout.write(self.style.SUCCESS(f'Created user: {username} (password: {password})'))
        else:
            self.stdout.write(f'User {username} already exists.')

        # Create token
        token, _ = Token.objects.get_or_create(user=user)
        self.stdout.write(self.style.SUCCESS(f'Auth Token for {username}: {token.key}'))

        # 2. Clear old data for this teacher
        Student.objects.filter(teacher=user).delete()
        Notice.objects.filter(teacher=user).delete()
        self.stdout.write('Cleared existing students, tasks, attendances, grades, behavior remarks, and notices.')

        # 3. Create Students
        students_data = [
            {'name': 'Aarav Sharma', 'roll_number': '101', 'grade': 'Class 10-A', 'email': 'aarav@gmail.com', 'guardian_name': 'Rakesh Sharma', 'guardian_phone': '9876543201'},
            {'name': 'Diya Patel', 'roll_number': '102', 'grade': 'Class 10-A', 'email': 'diya@gmail.com', 'guardian_name': 'Amit Patel', 'guardian_phone': '9876543202'},
            {'name': 'Kabir Singh', 'roll_number': '103', 'grade': 'Class 10-A', 'email': 'kabir@gmail.com', 'guardian_name': 'Jaspreet Singh', 'guardian_phone': '9876543203'},
            {'name': 'Isha Verma', 'roll_number': '104', 'grade': 'Class 10-B', 'email': 'isha@gmail.com', 'guardian_name': 'Sanjay Verma', 'guardian_phone': '9876543204'},
            {'name': 'Rohan Das', 'roll_number': '105', 'grade': 'Class 10-B', 'email': 'rohan@gmail.com', 'guardian_name': 'Milan Das', 'guardian_phone': '9876543205'},
            {'name': 'Ananya Reddy', 'roll_number': '106', 'grade': 'Class 10-B', 'email': 'ananya@gmail.com', 'guardian_name': 'Nikhil Reddy', 'guardian_phone': '9876543206'},
        ]

        students = []
        for s in students_data:
            student = Student.objects.create(
                teacher=user,
                name=s['name'],
                roll_number=s['roll_number'],
                grade=s['grade'],
                email=s['email'],
                guardian_name=s['guardian_name'],
                guardian_phone=s['guardian_phone']
            )
            students.append(student)
            self.stdout.write(f'Created student: {student.name}')

        # 4. Create Tasks for Students
        task_titles = [
            ('Math Homework - Chapter 3', 'Solve exercise 3.1 to 3.4 on notebook and submit.'),
            ('Science Project Proposal', 'Choose a topic for the science exhibit and write a 1-page proposal.'),
            ('English Literature Essay', 'Write a 500-word critical appreciation of the poem "The Road Not Taken".'),
            ('History Notes - French Revolution', 'Read Chapter 4 and summarize the main causes of the French Revolution.'),
            ('Computer Lab Assignment', 'Write a Python program to find prime numbers and show output screenshots.'),
            ('Geography Map Practice', 'Mark major rivers and mountain ranges on the outline map of India.')
        ]

        today = datetime.date.today()

        for student in students:
            # Assign 2-3 random tasks to each student
            assigned_tasks = random.sample(task_titles, k=random.randint(2, 4))
            for title, desc in assigned_tasks:
                due_days = random.randint(-2, 5)
                due_date = today + datetime.timedelta(days=due_days)
                status = random.choice(['PENDING', 'COMPLETED'])
                
                task = Task.objects.create(
                    student=student,
                    title=title,
                    description=desc,
                    due_date=due_date,
                    status=status
                )
                
                if status == 'COMPLETED':
                    task.updated_at = timezone.now() - datetime.timedelta(hours=random.randint(1, 24))
                    task.save()
                    
            self.stdout.write(f'Assigned tasks to {student.name}')

        # 5. Create Attendance for past 5 school days
        self.stdout.write('Seeding attendance registers...')
        statuses = ['PRESENT', 'PRESENT', 'PRESENT', 'PRESENT', 'ABSENT', 'LATE', 'LEAVE']
        # Past 5 dates (excluding Sundays)
        dates = []
        curr = today
        while len(dates) < 5:
            curr -= datetime.timedelta(days=1)
            if curr.weekday() != 6: # Skip Sundays
                dates.append(curr)

        for d in dates:
            for student in students:
                # Weighted random status favoring PRESENT
                status = random.choice(statuses)
                remarks = ''
                if status == 'ABSENT':
                    remarks = random.choice(['Sick leave notice sent', 'Absent without info', 'Family event'])
                elif status == 'LATE':
                    remarks = 'Missed school bus'
                elif status == 'LEAVE':
                    remarks = 'Parent submitted leave request'
                    
                Attendance.objects.create(
                    student=student,
                    date=d,
                    status=status,
                    remarks=remarks
                )

        # 6. Create Grades
        self.stdout.write('Seeding gradebook scoresheets...')
        exams = ['Unit Test 1', 'Midterm Exam']
        subjects = ['Mathematics', 'Science', 'English']
        
        for exam in exams:
            for subject in subjects:
                max_marks = 100.0 if 'Exam' in exam else 25.0
                for student in students:
                    # Randomize marks obtained (favoring pass scores)
                    marks = round(random.uniform(0.5 * max_marks, 0.98 * max_marks), 1)
                    remarks = ''
                    pct = (marks / max_marks) * 100
                    if pct >= 90:
                        remarks = 'Excellent performance!'
                    elif pct < 60:
                        remarks = 'Needs improvement'

                    Grade.objects.create(
                        student=student,
                        exam_name=exam,
                        subject=subject,
                        marks_obtained=marks,
                        max_marks=max_marks,
                        remarks=remarks
                    )

        # 7. Create Behavior Remarks
        self.stdout.write('Seeding behavior logs...')
        positive_remarks = [
            ('Active Participant', 'Always participates in classroom discussions and asks smart questions.'),
            ('Peer Helper', 'Helped classmates with complex geometry notes.'),
            ('Disciplined Conduct', 'Always punctual and maintains notebook neatly.')
        ]
        warning_remarks = [
            ('Incomplete Notebook', 'Notebook exercise 2.3 was incomplete during checking.'),
            ('Distracted in Class', 'Repeatedly talking to classmates during lecture.')
        ]

        for student in students:
            # Assign 1 positive or 1 warning randomly
            if random.choice([True, False]):
                title, desc = random.choice(positive_remarks)
                BehaviorRemark.objects.create(
                    student=student,
                    type='POSITIVE',
                    title=title,
                    description=desc
                )
            if random.choice([True, False, False]):
                title, desc = random.choice(warning_remarks)
                BehaviorRemark.objects.create(
                    student=student,
                    type='WARNING',
                    title=title,
                    description=desc
                )

        # 8. Create Notices/Circular announcements
        self.stdout.write('Seeding noticeboard bulletins...')
        Notice.objects.create(
            teacher=user,
            title='Midterm Exam Time Table',
            content='Dear parents, the midterm examination is scheduled to begin next Monday. Detailed timetable has been uploaded on files. Please ensure children prepare well.'
        )
        Notice.objects.create(
            teacher=user,
            title='Parent Teacher Meeting (PTM)',
            content='This is to inform all parents that a PTM will be held on Saturday between 9:00 AM and 12:30 PM. Report cards for Unit Test 1 will be distributed. Punctuality is requested.'
        )

        self.stdout.write(self.style.SUCCESS('Successfully seeded database with upgraded professional data!'))
