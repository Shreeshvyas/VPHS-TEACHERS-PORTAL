from django.urls import path, include
from django.views.generic import RedirectView
from rest_framework.routers import DefaultRouter
from . import views

# DRF Router for API endpoints
router = DefaultRouter()
router.register(r'students', views.StudentViewSet, basename='api-student')
router.register(r'tasks', views.TaskViewSet, basename='api-task')
router.register(r'attendance', views.AttendanceViewSet, basename='api-attendance')
router.register(r'grades', views.GradeViewSet, basename='api-grade')
router.register(r'remarks', views.BehaviorRemarkViewSet, basename='api-remark')
router.register(r'notices', views.NoticeViewSet, basename='api-notice')
router.register(r'teachers', views.TeacherViewSet, basename='api-teacher')

urlpatterns = [
    # Web Portal URLs
    path('', RedirectView.as_view(url='dashboard/', permanent=False), name='index'),
    path('login/', views.web_login, name='login'),
    path('logout/', views.web_logout, name='logout'),
    path('dashboard/', views.web_dashboard, name='dashboard'),
    path('students/', views.web_students, name='students'),
    path('students/<int:pk>/', views.web_student_detail, name='student_detail'),
    path('students/<int:pk>/delete/', views.web_delete_student, name='delete_student'),
    path('tasks/', views.web_tasks, name='tasks'),
    path('tasks/<int:pk>/complete/', views.web_complete_task, name='complete_task'),
    path('attendance/', views.web_attendance, name='attendance'),
    path('gradebook/', views.web_gradebook, name='gradebook'),
    path('notices/', views.web_notices, name='notices'),
    path('notices/<int:pk>/delete/', views.web_delete_notice, name='delete_notice'),
    path('profile/', views.web_profile, name='web_profile'),
    path('teachers/', views.web_teachers, name='web_teachers'),
    path('teachers/<int:pk>/', views.web_teacher_detail, name='web_teacher_detail'),
    
    # API endpoints for Flutter App
    path('api/', include(router.urls)),
    path('api/login/', views.CustomObtainAuthToken.as_view(), name='api_login'),
    path('api/dashboard/', views.ApiDashboardStatsView.as_view(), name='api_dashboard'),
    path('api/profile/', views.UserProfileView.as_view(), name='api_profile'),
    path('api/profile/change-password/', views.ChangePasswordView.as_view(), name='api_change_password'),
    path('api/profile/documents/', views.UserProfileDocumentsView.as_view(), name='api_profile_documents'),
    path('api/profile/documents/<int:pk>/', views.UserProfileDocumentDetailView.as_view(), name='api_profile_document_detail'),
]

