from django.contrib import admin
from .models import Student, Task, Attendance, Grade, BehaviorRemark, Notice, TeacherProfile, TeacherDocument

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ('name', 'roll_number', 'grade', 'teacher', 'created_at')
    search_fields = ('name', 'roll_number', 'grade')
    list_filter = ('grade', 'teacher')


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'student', 'due_date', 'status', 'created_at')
    search_fields = ('title', 'student__name', 'student__roll_number')
    list_filter = ('status', 'due_date')


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ('student', 'date', 'status', 'remarks')
    list_filter = ('status', 'date', 'student__grade')
    search_fields = ('student__name', 'student__roll_number')


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ('student', 'exam_name', 'subject', 'marks_obtained', 'max_marks', 'percentage_display')
    list_filter = ('exam_name', 'subject', 'student__grade')
    search_fields = ('student__name', 'exam_name', 'subject')

    def percentage_display(self, obj):
        return f"{obj.percentage}% ({obj.grade_letter})"
    percentage_display.short_description = 'Percentage / Grade'


@admin.register(BehaviorRemark)
class BehaviorRemarkAdmin(admin.ModelAdmin):
    list_display = ('student', 'type', 'title', 'created_at')
    list_filter = ('type', 'created_at')
    search_fields = ('student__name', 'title')


@admin.register(Notice)
class NoticeAdmin(admin.ModelAdmin):
    list_display = ('title', 'teacher', 'created_at')
    search_fields = ('title', 'content')


@admin.register(TeacherProfile)
class TeacherProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'employee_id', 'phone', 'class_assigned')
    search_fields = ('user__username', 'employee_id', 'phone')


@admin.register(TeacherDocument)
class TeacherDocumentAdmin(admin.ModelAdmin):
    list_display = ('name', 'profile', 'uploaded_at')
    search_fields = ('name', 'profile__user__username')
