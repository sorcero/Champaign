const ActionBar = Backbone.View.extend({

  el: '.action-bar',

  events: {
    'click .action-bar__open-button': 'reveal',
    'click .action-bar__close-button': 'hide',
    'click .action-bar__expand-arrow': 'toggleBlurb',
    'click .action-bar__top': 'toggleBlurb',
  },

  initialize: function() {
    this.isSticky = false;
    if (!this.isMobile()) {
      this.makeSticky();
    }
    // can't use events hash cause scoped to window
    $(window).on('resize', () => this.questionSticky());
  },

  isMobile: function() {
    return $('.mobile-indicator').is(':visible');
  },

  hide: function() {
    this.$el.addClass('action-bar--mobile-view--closed').removeClass('action-bar--mobile-view--open');
  },

  reveal: function() {
    this.$el.removeClass('action-bar--mobile-view--closed').addClass('action-bar--mobile-view--open');
  },

  toggleBlurb: function() {
    if (this.$('.action-bar__expand-arrow').hasClass('action-bar__expand-arrow--expanded')) {
      this.expandBlurb();
    } else {
      this.collapseBlurb();
    }
    this.$('.action-bar__expand-arrow').toggleClass('action-bar__expand-arrow--expanded');
  },

  expandBlurb: function() {
    this.$('.action-bar__main').css('top', '');
    this.$el.parent('.sticky-wrapper').css('top', '');
  },

  collapseBlurb: function() {
    const height = this.$('.action-bar__top').outerHeight();
    this.$('.action-bar__main').css('top', `${height}px`);
    this.$el.parent('.sticky-wrapper').css('top', `-${height}px`);
  },

  makeSticky: function() {
    if(!this.isSticky) {
      this.$el.sticky({topSpacing:0});
      this.isSticky = true;
    }
  },

  unmakeSticky: function() {
    if(this.isSticky) {
      this.$el.unstick();
      this.isSticky = false;
    }
  },

  questionSticky: function() {
    if(this.isMobile()) {
      this.unmakeSticky();
    } else {
      this.makeSticky();
    }
  },

});

module.exports = ActionBar;
