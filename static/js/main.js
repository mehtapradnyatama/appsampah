// ========================
// Global Variables
// ========================

let currentUser = null;
let classifications = [];
let charts = {};

// ========================
// Utility Functions
// ========================

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function showNotification(message, type = 'info', duration = 5000) {
    const notification = document.createElement('div');
    notification.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
    notification.style.cssText = `
        top: 100px;
        right: 20px;
        z-index: 9999;
        min-width: 300px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    `;
    
    notification.innerHTML = `
        <div class="d-flex align-items-center">
            <i class="fas fa-${getIconForType(type)} me-2"></i>
            <span>${message}</span>
            <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    // Auto remove after duration
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, duration);
}

function getIconForType(type) {
    const icons = {
        'success': 'check-circle',
        'danger': 'exclamation-circle',
        'warning': 'exclamation-triangle',
        'info': 'info-circle'
    };
    return icons[type] || 'info-circle';
}

// ========================
// Image Handling
// ========================

class ImageHandler {
    constructor() {
        this.maxSize = 16 * 1024 * 1024; // 16MB
        this.allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    }

    validateImage(file) {
        const errors = [];
        
        if (!file) {
            errors.push('No file selected');
            return errors;
        }
        
        if (!this.allowedTypes.includes(file.type)) {
            errors.push('Invalid file type. Please use JPG, JPEG, or PNG files.');
        }
        
        if (file.size > this.maxSize) {
            errors.push(`File size too large. Maximum size is ${formatFileSize(this.maxSize)}.`);
        }
        
        return errors;
    }

    createPreview(file, callback) {
        const reader = new FileReader();
        reader.onload = function(e) {
            callback(null, e.target.result);
        };
        reader.onerror = function() {
            callback('Failed to read file', null);
        };
        reader.readAsDataURL(file);
    }

    compressImage(file, maxWidth = 1024, quality = 0.8) {
        return new Promise((resolve) => {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            const img = new Image();
            
            img.onload = () => {
                const ratio = Math.min(maxWidth / img.width, maxWidth / img.height);
                canvas.width = img.width * ratio;
                canvas.height = img.height * ratio;
                
                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                
                canvas.toBlob(resolve, file.type, quality);
            };
            
            img.src = URL.createObjectURL(file);
        });
    }
}

// ========================
// Classification Analytics
// ========================

class ClassificationAnalytics {
    constructor() {
        this.wasteColors = {
            cardboard: '#f39c12',
            glass: '#27ae60',
            metal: '#3498db',
            paper: '#9b59b6',
            plastic: '#e74c3c'
        };
    }

    calculateStats(classifications) {
        const stats = {
            total: classifications.length,
            categories: {},
            averageConfidence: 0,
            recentActivity: [],
            monthlyData: {},
            environmentalImpact: {
                co2Saved: 0,
                itemsRecycled: 0,
                wasteReduced: 0
            }
        };

        if (classifications.length === 0) return stats;

        let totalConfidence = 0;
        
        classifications.forEach(classification => {
            const category = classification.predicted_class;
            const confidence = classification.confidence;
            const date = new Date(classification.created_at);
            const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            
            // Category counts
            stats.categories[category] = (stats.categories[category] || 0) + 1;
            
            // Confidence tracking
            totalConfidence += confidence;
            
            // Monthly data
            if (!stats.monthlyData[monthKey]) {
                stats.monthlyData[monthKey] = { count: 0, categories: {} };
            }
            stats.monthlyData[monthKey].count++;
            stats.monthlyData[monthKey].categories[category] = 
                (stats.monthlyData[monthKey].categories[category] || 0) + 1;
            
            // Recent activity (last 7 days)
            const daysDiff = (new Date() - date) / (1000 * 60 * 60 * 24);
            if (daysDiff <= 7) {
                stats.recentActivity.push(classification);
            }
        });

        stats.averageConfidence = totalConfidence / classifications.length;
        
        // Calculate environmental impact
        stats.environmentalImpact.co2Saved = classifications.length * 0.5; // 0.5kg CO2 per item
        stats.environmentalImpact.itemsRecycled = classifications.length;
        stats.environmentalImpact.wasteReduced = classifications.length * 0.3; // 0.3kg per item

        return stats;
    }

    createDistributionChart(canvasId, data) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        const labels = Object.keys(data);
        const values = Object.values(data);
        const colors = labels.map(label => this.wasteColors[label.toLowerCase()] || '#95a5a6');

        if (charts[canvasId]) {
            charts[canvasId].destroy();
        }

        charts[canvasId] = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels.map(label => label.charAt(0).toUpperCase() + label.slice(1)),
                datasets: [{
                    data: values,
                    backgroundColor: colors,
                    borderColor: colors,
                    borderWidth: 2,
                    hoverBorderWidth: 3
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true,
                            font: {
                                size: 12,
                                weight: '600'
                            }
                        }
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0,0,0,0.8)',
                        titleColor: '#fff',
                        bodyColor: '#fff',
                        borderColor: '#ddd',
                        borderWidth: 1,
                        callbacks: {
                            label: function(context) {
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((context.parsed / total) * 100).toFixed(1);
                                return `${context.label}: ${context.parsed} (${percentage}%)`;
                            }
                        }
                    }
                },
                animation: {
                    animateScale: true,
                    animateRotate: true,
                    duration: 1000
                }
            }
        });

        return charts[canvasId];
    }

    createTrendChart(canvasId, monthlyData) {
        const ctx = document.getElementById(canvasId);
        if (!ctx) return null;

        const sortedMonths = Object.keys(monthlyData).sort();
        const data = sortedMonths.map(month => monthlyData[month].count);

        if (charts[canvasId]) {
            charts[canvasId].destroy();
        }

        charts[canvasId] = new Chart(ctx, {
            type: 'line',
            data: {
                labels: sortedMonths.map(month => {
                    const [year, monthNum] = month.split('-');
                    return new Date(year, monthNum - 1).toLocaleDateString('en-US', { 
                        month: 'short', 
                        year: 'numeric' 
                    });
                }),
                datasets: [{
                    label: 'Classifications',
                    data: data,
                    borderColor: '#3498db',
                    backgroundColor: 'rgba(52, 152, 219, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: '#3498db',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointRadius: 5,
                    pointHoverRadius: 7
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0,0,0,0.8)',
                        titleColor: '#fff',
                        bodyColor: '#fff'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: 'rgba(0,0,0,0.1)'
                        },
                        ticks: {
                            color: '#6c757d'
                        }
                    },
                    x: {
                        grid: {
                            color: 'rgba(0,0,0,0.1)'
                        },
                        ticks: {
                            color: '#6c757d'
                        }
                    }
                },
                animation: {
                    duration: 1000,
                    easing: 'easeInOutQuart'
                }
            }
        });

        return charts[canvasId];
    }
}

// ========================
// API Client
// ========================

class APIClient {
    constructor() {
        this.baseURL = window.location.origin;
    }

    async fetchStats() {
        try {
            const response = await fetch(`${this.baseURL}/api/stats`);
            if (!response.ok) throw new Error('Failed to fetch stats');
            return await response.json();
        } catch (error) {
            console.error('Error fetching stats:', error);
            throw error;
        }
    }

    async uploadImage(formData, onProgress = null) {
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            
            xhr.upload.onprogress = (event) => {
                if (event.lengthComputable && onProgress) {
                    const percentComplete = (event.loaded / event.total) * 100;
                    onProgress(percentComplete);
                }
            };
            
            xhr.onload = () => {
                if (xhr.status === 200) {
                    resolve(xhr.response);
                } else {
                    reject(new Error(`Upload failed: ${xhr.status}`));
                }
            };
            
            xhr.onerror = () => reject(new Error('Upload failed'));
            
            xhr.open('POST', `${this.baseURL}/classify`);
            xhr.send(formData);
        });
    }
}

// ========================
// Page-Specific Handlers
// ========================

// Classification Page Handler
class ClassificationHandler {
    constructor() {
        this.imageHandler = new ImageHandler();
        this.apiClient = new APIClient();
        this.currentFile = null;
        this.isUploading = false;
        
        this.initializeElements();
        this.attachEventListeners();
    }

    initializeElements() {
        this.uploadArea = document.getElementById('uploadArea');
        this.fileInput = document.getElementById('fileInput');
        this.previewSection = document.getElementById('previewSection');
        this.imagePreview = document.getElementById('imagePreview');
        this.fileDetails = document.getElementById('fileDetails');
        this.classifyBtn = document.getElementById('classifyBtn');
        this.uploadForm = document.getElementById('uploadForm');
        this.loadingSpinner = document.getElementById('loadingSpinner');
        this.progressBar = this.createProgressBar();
    }

    createProgressBar() {
        const progressContainer = document.createElement('div');
        progressContainer.className = 'progress mt-3';
        progressContainer.style.display = 'none';
        
        const progressBar = document.createElement('div');
        progressBar.className = 'progress-bar progress-bar-striped progress-bar-animated';
        progressBar.style.width = '0%';
        
        progressContainer.appendChild(progressBar);
        
        if (this.uploadForm) {
            this.uploadForm.appendChild(progressContainer);
        }
        
        return { container: progressContainer, bar: progressBar };
    }

    attachEventListeners() {
        if (!this.uploadArea || !this.fileInput) return;

        // Upload area click
        this.uploadArea.addEventListener('click', (e) => {
            if (e.target === this.uploadArea || this.uploadArea.contains(e.target)) {
                this.fileInput.click();
            }
        });

        // Drag and drop
        this.uploadArea.addEventListener('dragover', this.handleDragOver.bind(this));
        this.uploadArea.addEventListener('dragleave', this.handleDragLeave.bind(this));
        this.uploadArea.addEventListener('drop', this.handleDrop.bind(this));

        // File input change
        this.fileInput.addEventListener('change', this.handleFileSelect.bind(this));

        // Form submission
        if (this.uploadForm) {
            this.uploadForm.addEventListener('submit', this.handleFormSubmit.bind(this));
        }
    }

    handleDragOver(e) {
        e.preventDefault();
        this.uploadArea.classList.add('drag-over');
    }

    handleDragLeave(e) {
        e.preventDefault();
        this.uploadArea.classList.remove('drag-over');
    }

    handleDrop(e) {
        e.preventDefault();
        this.uploadArea.classList.remove('drag-over');
        
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            this.processFile(files[0]);
        }
    }

    handleFileSelect(e) {
        if (e.target.files.length > 0) {
            this.processFile(e.target.files[0]);
        }
    }

    processFile(file) {
        const errors = this.imageHandler.validateImage(file);
        
        if (errors.length > 0) {
            showNotification(errors.join('<br>'), 'danger');
            return;
        }

        this.currentFile = file;
        
        this.imageHandler.createPreview(file, (error, dataUrl) => {
            if (error) {
                showNotification('Failed to create image preview', 'danger');
                return;
            }
            
            this.showPreview(dataUrl, file);
        });
    }

    showPreview(dataUrl, file) {
        if (!this.imagePreview || !this.previewSection || !this.fileDetails) return;

        this.imagePreview.src = dataUrl;
        this.previewSection.style.display = 'block';
        this.uploadArea.style.display = 'none';
        
        if (this.classifyBtn) {
            this.classifyBtn.disabled = false;
        }

        this.fileDetails.innerHTML = `
            <div class="row">
                <div class="col-sm-6">
                    <p><strong>File:</strong> ${file.name}</p>
                    <p><strong>Size:</strong> ${formatFileSize(file.size)}</p>
                </div>
                <div class="col-sm-6">
                    <p><strong>Type:</strong> ${file.type}</p>
                    <p><strong>Modified:</strong> ${formatDate(file.lastModified)}</p>
                </div>
            </div>
        `;
    }

    handleFormSubmit(e) {
        if (this.isUploading) {
            e.preventDefault();
            return;
        }

        this.isUploading = true;
        
        if (this.classifyBtn) {
            this.classifyBtn.disabled = true;
            this.classifyBtn.innerHTML = `
                <i class="fas fa-brain me-2"></i>Processing...
                <span class="spinner-border spinner-border-sm ms-2"></span>
            `;
        }

        // Show progress bar
        if (this.progressBar.container) {
            this.progressBar.container.style.display = 'block';
        }
    }

    removeImage() {
        this.currentFile = null;
        
        if (this.fileInput) this.fileInput.value = '';
        if (this.previewSection) this.previewSection.style.display = 'none';
        if (this.uploadArea) this.uploadArea.style.display = 'block';
        if (this.classifyBtn) this.classifyBtn.disabled = true;
        
        this.isUploading = false;
    }
}

// Dashboard Handler
class DashboardHandler {
    constructor() {
        this.analytics = new ClassificationAnalytics();
        this.apiClient = new APIClient();
        
        this.initializeDashboard();
    }

    async initializeDashboard() {
        try {
            // Load user statistics
            await this.loadStats();
            
            // Initialize animations
            this.animateCounters();
            
        } catch (error) {
            console.error('Error initializing dashboard:', error);
            showNotification('Failed to load dashboard data', 'danger');
        }
    }

    async loadStats() {
        try {
            const stats = await this.apiClient.fetchStats();
            this.updateDashboard(stats);
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    updateDashboard(stats) {
        // Update stat cards with animation
        this.updateStatCard('total-classifications', stats.total_classifications);
        this.updateStatCard('recent-classifications', stats.recent_classifications);
        
        // Update charts
        if (stats.class_distribution && Object.keys(stats.class_distribution).length > 0) {
            this.analytics.createDistributionChart('distributionChart', stats.class_distribution);
        }
    }

    updateStatCard(id, value) {
        const element = document.getElementById(id);
        if (element) {
            this.animateNumber(element, 0, value, 1000);
        }
    }

    animateNumber(element, start, end, duration) {
        const startTime = performance.now();
        
        const animate = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            const current = Math.floor(start + (end - start) * this.easeOutQuart(progress));
            element.textContent = current.toLocaleString();
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        };
        
        requestAnimationFrame(animate);
    }

    easeOutQuart(t) {
        return 1 - Math.pow(1 - t, 4);
    }

    animateCounters() {
        const counters = document.querySelectorAll('[data-count]');
        
        counters.forEach(counter => {
            const target = parseInt(counter.dataset.count);
            this.animateNumber(counter, 0, target, 2000);
        });
    }
}

// ========================
// Page Initialization
// ========================

document.addEventListener('DOMContentLoaded', function() {
    // Initialize global components
    initializeTooltips();
    initializeModals();
    initializeNavigation();
    
    // Page-specific initialization
    const currentPage = document.body.dataset.page;
    
    switch (currentPage) {
        case 'classify':
            new ClassificationHandler();
            break;
        case 'dashboard':
            new DashboardHandler();
            break;
        case 'index':
            initializeHomePage();
            break;
        default:
            // General page initialization
            break;
    }
});

// ========================
// Global Initializers
// ========================

function initializeTooltips() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
}

function initializeModals() {
    // Add modal event listeners if needed
    const modals = document.querySelectorAll('.modal');
    modals.forEach(modal => {
        modal.addEventListener('hidden.bs.modal', function () {
            // Clean up modal content when closed
            const modalBody = modal.querySelector('.modal-body');
            if (modalBody && modalBody.innerHTML.includes('spinner-border')) {
                modalBody.innerHTML = '';
            }
        });
    });
}

function initializeNavigation() {
    // Add active class to current page nav item
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('.navbar-nav .nav-link');
    
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.classList.add('active');
        }
    });
}

function initializeHomePage() {
    // Animate hero stats on scroll
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
            }
        });
    }, { threshold: 0.1 });

    const statsCards = document.querySelectorAll('.hero-stats .stat-card');
    statsCards.forEach(card => {
        observer.observe(card);
    });

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// ========================
// Global Event Handlers
// ========================

// Handle form validation
document.addEventListener('submit', function(e) {
    const form = e.target;
    if (form.classList.contains('needs-validation')) {
        if (!form.checkValidity()) {
            e.preventDefault();
            e.stopPropagation();
        }
        form.classList.add('was-validated');
    }
});

// Handle copy to clipboard
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showNotification('Copied to clipboard!', 'success', 2000);
    }).catch(() => {
        showNotification('Failed to copy to clipboard', 'danger');
    });
}

// Handle image zoom modal
function showImageModal(imageSrc, title = '') {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.innerHTML = `
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">${title}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <img src="${imageSrc}" class="img-fluid" alt="${title}">
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
    
    modal.addEventListener('hidden.bs.modal', () => {
        modal.remove();
    });
}

// ========================
// Utility Functions for Global Use
// ========================

window.EcoClassify = {
    showNotification,
    copyToClipboard,
    showImageModal,
    formatDate,
    formatFileSize
};

// ========================
// Service Worker Registration
// ========================

if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}