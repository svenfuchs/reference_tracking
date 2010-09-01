require File.expand_path('../test_helper', __FILE__)

class Blog
  def id; 1 end
  def title; 'the title' end
  def posts; @posts ||= [Post.new] end
end

class Post
  def id; 1 end
  def title; 'the title' end
  def body; 'the body' end
  def blog; @blog ||= Blog.new end
  def author; @author ||= User.new end
end

class User
  def id; 1 end
end

class Controller
  extend ReferenceTracking::ActionController::ActMacro
  def blog; @blog ||= Blog.new end
  def post; @post ||= Post.new end
  def params; { :action => :show } end
end

# tracks :post                          # => post-1
# tracks 'post.title'                   # => post-1.title
# tracks :post => '.title'              # => post-1.title
# tracks :post => :blog                 # => blog-1
# tracks :post => %w(.title .body)      # => post-1.title, post-1.body
# tracks :post => [:blog, '.title']     # => blog-1, post-1.title
# tracks :post => { :blog => '.title' } # => blog-1.title
# tracks :blog => :posts                # => post-1, post-1, ...

class TrackerTest < Test::Unit::TestCase
  def teardown
    Controller.send(:remove_const, :Tracker) rescue
    @controller = nil
  end

  def controller
    @controller ||= Controller.new.tap { |c| c.send(:setup_reference_tracking) }
  end

  def references
    controller.instance_variable_get(:@_references)
  end

  def repeatedly
    2.times do
      references.clear
      yield
    end
  end

  test "tracking a target" do
    Controller.tracks(:post)
    repeatedly do
      controller.post
      assert_equal ['post-1'], references.tags
    end
  end

  test "tracking a method on a target (compact notation)" do
    Controller.tracks('post.title')
    repeatedly do
      post = controller.post
      assert_equal [], references
      controller.post.title
      assert_equal ['post-1:title'], references.tags
    end
  end

  test "tracking a method on a target (hash notation)" do
    Controller.tracks(:post => '.title')
    repeatedly do
      post = controller.post
      assert_equal [], references
      controller.post.title
      assert_equal ['post-1:title'], references.tags
    end
  end

  test "tracking a target on a target" do
    Controller.tracks(:post => :blog)
    repeatedly do
      controller.post
      assert_equal [], references
      controller.post.title
      assert_equal [], references
      controller.post.blog.title
      assert_equal ['blog-1'], references.tags
    end
  end

  # FIXME
  #
  # test "tracking a method on a target on a target (compact notation)" do
  #   Controller.tracks(:post => 'blog.title')
  #   repeatedly do
  #     controller.post
  #     assert_equal [], references
  #     controller.post.title
  #     assert_equal [], references
  #     controller.post.blog.title
  #     assert_equal ['blog-1:title'], references.tags
  #   end
  # end

  test "tracking a method on a target on a target (hash notation)" do
    Controller.tracks(:post => { :blog => '.title' })
    repeatedly do
      controller.post
      assert_equal [], references
      controller.post.title
      assert_equal [], references
      controller.post.blog.title
      assert_equal ['blog-1:title'], references.tags
    end
  end

  test "tracking an array of methods on a target" do
    Controller.tracks(:post => %w(.title .body))
    repeatedly do
      controller.post.title
      controller.post.body
      assert_equal ['post-1:title', 'post-1:body'], references.tags
    end
  end

  test "tracking multiple targets on a target" do
    Controller.tracks(:post => [:author, { :blog => '.title' }])
    repeatedly do
      controller.post.author
      controller.post.blog.title
      assert_equal ['user-1', 'blog-1:title'], references.tags
    end
  end

  test "tracking a target that returns an array on a target" do
    Controller.tracks(:blog => :posts)
    repeatedly do
      controller.blog
      assert_equal [], references
      # FIXME this probably should not track anything yet. instead it should
      # kick in when any method on a post was called? because otherwise named
      # scopes would be evaluated early?
      controller.blog.posts
      assert_equal ['post-1'], references.tags
    end
  end

  test "can combine notations" do
    Controller.tracks(:post => [:blog, '.title']) # 
    repeatedly do
      controller.post.blog
      controller.post.title
      assert_equal ['blog-1', 'post-1:title'], references.tags
    end
  end
end