// Image Loading State Manager
// Handles showing/hiding loading placeholders for TOC scan images
document.addEventListener('DOMContentLoaded', function() {
  const imageLoaders = document.querySelectorAll('.image-loader');

  imageLoaders.forEach(function(img) {
    const imageId = img.dataset.imageId;

    if (!imageId) return;

    const spinner = document.querySelector('.image-loading-spinner[data-image-id="' + imageId + '"]');
    const container = img.closest('.image-loading-container');

    if (!container || !spinner) return;

    // Handle successful image load
    img.addEventListener('load', function() {
      img.classList.add('image-loaded');
      spinner.classList.add('hidden');
      container.style.animation = 'none';
    });

    // Handle image load error
    img.addEventListener('error', function() {
      container.classList.add('image-error');
      container.style.animation = 'none';
      spinner.style.display = 'none';

      // Replace image with error message
      const errorMsg = document.createElement('div');
      errorMsg.className = 'error-message';
      errorMsg.innerHTML = '<div class="error-icon">⚠️</div><div>Image failed to load</div>';
      img.style.display = 'none';
      container.appendChild(errorMsg);
    });
  });
});
