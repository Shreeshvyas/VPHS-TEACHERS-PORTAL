from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Student, Task, Attendance, Grade, BehaviorRemark, Notice, TeacherProfile

class TeacherProfileSerializer(serializers.ModelSerializer):
    remaining_leaves = serializers.ReadOnlyField()

    class Meta:
        model = TeacherProfile
        fields = [
            'phone', 'class_assigned', 'total_leaves', 'leaves_taken',
            'remaining_leaves', 'esic_id', 'bank_account_number',
            'bank_name', 'ifsc_code', 'profile_picture', 'document_file'
        ]


class UserSerializer(serializers.ModelSerializer):
    profile = TeacherProfileSerializer(read_only=True)
    is_super_admin = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'profile', 'is_super_admin']

    def get_is_super_admin(self, obj):
        return obj.is_superuser or obj.is_staff



class TaskSerializer(serializers.ModelSerializer):
    student_name = serializers.ReadOnlyField(source='student.name')
    student_roll = serializers.ReadOnlyField(source='student.roll_number')
    student_grade = serializers.ReadOnlyField(source='student.grade')

    class Meta:
        model = Task
        fields = [
            'id', 'student', 'student_name', 'student_roll', 'student_grade',
            'title', 'description', 'due_date', 'status', 'created_at', 'updated_at'
        ]


class AttendanceSerializer(serializers.ModelSerializer):
    student_name = serializers.ReadOnlyField(source='student.name')
    student_roll = serializers.ReadOnlyField(source='student.roll_number')
    student_grade = serializers.ReadOnlyField(source='student.grade')

    class Meta:
        model = Attendance
        fields = [
            'id', 'student', 'student_name', 'student_roll', 'student_grade',
            'date', 'status', 'remarks'
        ]


class GradeSerializer(serializers.ModelSerializer):
    student_name = serializers.ReadOnlyField(source='student.name')
    student_roll = serializers.ReadOnlyField(source='student.roll_number')
    student_grade = serializers.ReadOnlyField(source='student.grade')
    percentage = serializers.ReadOnlyField()
    grade_letter = serializers.ReadOnlyField()

    class Meta:
        model = Grade
        fields = [
            'id', 'student', 'student_name', 'student_roll', 'student_grade',
            'exam_name', 'subject', 'marks_obtained', 'max_marks', 'remarks',
            'percentage', 'grade_letter', 'created_at'
        ]


class BehaviorRemarkSerializer(serializers.ModelSerializer):
    student_name = serializers.ReadOnlyField(source='student.name')
    student_roll = serializers.ReadOnlyField(source='student.roll_number')
    student_grade = serializers.ReadOnlyField(source='student.grade')

    class Meta:
        model = BehaviorRemark
        fields = [
            'id', 'student', 'student_name', 'student_roll', 'student_grade',
            'type', 'title', 'description', 'created_at'
        ]


class NoticeSerializer(serializers.ModelSerializer):
    teacher_name = serializers.SerializerMethodField()

    class Meta:
        model = Notice
        fields = ['id', 'teacher', 'teacher_name', 'title', 'content', 'created_at']
        read_only_fields = ['teacher']

    def get_teacher_name(self, obj):
        return f"{obj.teacher.first_name} {obj.teacher.last_name}".strip() or obj.teacher.username


class StudentSerializer(serializers.ModelSerializer):
    tasks = TaskSerializer(many=True, read_only=True)
    attendances = AttendanceSerializer(many=True, read_only=True)
    grades = GradeSerializer(many=True, read_only=True)
    behavior_remarks = BehaviorRemarkSerializer(many=True, read_only=True)
    
    task_count = serializers.SerializerMethodField()
    pending_task_count = serializers.SerializerMethodField()
    attendance_percentage = serializers.SerializerMethodField()
    average_grade = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = [
            'id', 'teacher', 'name', 'roll_number', 'grade', 'email',
            'guardian_name', 'guardian_phone', 'created_at', 'tasks',
            'attendances', 'grades', 'behavior_remarks', 'task_count',
            'pending_task_count', 'attendance_percentage', 'average_grade'
        ]
        read_only_fields = ['teacher']

    def get_task_count(self, obj):
        return obj.tasks.count()

    def get_pending_task_count(self, obj):
        return obj.tasks.filter(status='PENDING').count()

    def get_attendance_percentage(self, obj):
        total = obj.attendances.count()
        if total == 0:
            return 100.0 # Default if no attendance marked yet
        present_or_late = obj.attendances.filter(status__in=['PRESENT', 'LATE']).count()
        return round((present_or_late / total) * 100, 1)

    def get_average_grade(self, obj):
        student_grades = obj.grades.all()
        if not student_grades.exists():
            return 0.0
        total_pct = sum(g.percentage for g in student_grades)
        return round(total_pct / student_grades.count(), 1)
