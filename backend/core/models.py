from django.db import models
from django.contrib.auth.models import User

# Create your models here.

class Student(models.Model):
    teacher = models.ForeignKey(User, on_delete=models.CASCADE, related_name='students')
    name = models.CharField(max_length=100)
    roll_number = models.CharField(max_length=20)
    grade = models.CharField(max_length=50, verbose_name="Class/Grade")
    email = models.EmailField(blank=True, null=True)
    guardian_name = models.CharField(max_length=100, blank=True, null=True)
    guardian_phone = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        unique_together = ('teacher', 'roll_number')

    def __str__(self):
        return f"{self.name} (Roll: {self.roll_number}) - Grade: {self.grade}"


class Task(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('COMPLETED', 'Completed'),
    ]

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='tasks')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    due_date = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['due_date', '-created_at']

    def __str__(self):
        return f"{self.title} - {self.student.name} ({self.status})"


class Attendance(models.Model):
    STATUS_CHOICES = [
        ('PRESENT', 'Present'),
        ('ABSENT', 'Absent'),
        ('LATE', 'Late'),
        ('LEAVE', 'Leave'),
    ]

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='attendances')
    date = models.DateField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES)
    remarks = models.CharField(max_length=200, blank=True, null=True)

    class Meta:
        ordering = ['-date']
        unique_together = ('student', 'date')

    def __str__(self):
        return f"{self.student.name} - {self.date} ({self.status})"


class Grade(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='grades')
    exam_name = models.CharField(max_length=100) # e.g. Unit Test 1, Midterm, Final
    subject = models.CharField(max_length=100)    # e.g. Mathematics, English
    marks_obtained = models.FloatField()
    max_marks = models.FloatField()
    remarks = models.CharField(max_length=200, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    @property
    def percentage(self):
        if self.max_marks > 0:
            return round((self.marks_obtained / self.max_marks) * 100, 1)
        return 0.0

    @property
    def grade_letter(self):
        pct = self.percentage
        if pct >= 90: return 'A+'
        if pct >= 80: return 'A'
        if pct >= 70: return 'B'
        if pct >= 60: return 'C'
        if pct >= 50: return 'D'
        return 'F'

    def __str__(self):
        return f"{self.student.name} - {self.subject} ({self.exam_name}): {self.marks_obtained}/{self.max_marks}"


class BehaviorRemark(models.Model):
    TYPE_CHOICES = [
        ('POSITIVE', 'Positive Badge'),
        ('WARNING', 'Disciplinary Warning'),
    ]

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='behavior_remarks')
    type = models.CharField(max_length=15, choices=TYPE_CHOICES)
    title = models.CharField(max_length=100) # e.g. "Star Student", "Distracted in Class"
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.student.name} - {self.title} ({self.type})"


class Notice(models.Model):
    teacher = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notices')
    title = models.CharField(max_length=200)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} - By {self.teacher.username}"
