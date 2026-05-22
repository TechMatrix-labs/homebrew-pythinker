class PythinkerAi < Formula
  desc "Tiny async agent framework with chat channels, memory, MCP, and an OpenAI-compatible API"
  homepage "https://github.com/mohamed-elkholy95/Pythinker-ai"
  url "https://files.pythonhosted.org/packages/75/a3/3bef631278b6c30a300482fddc235cadfcf7d415a77b39c9b99b189f524d/pythinker_ai-2.7.0.tar.gz"
  sha256 "e802352d350e2e5b1c5b8256b31f065d1af1696633df4f2acba123867d25ad57"
  license "MIT"

  depends_on "python@3.12"

  conflicts_with "pythinker-code",
    because: "both install a `pythinker` executable into bin/"

  def install
    # Provision a plain venv and let pip resolve prebuilt wheels for
    # the Rust/C-extension dependency tree (cryptography, pydantic-core,
    # jiter, tiktoken, rpds-py, primp, Pillow, lxml, …). Using
    # `virtualenv_install_with_resources` would force `--no-binary :all:`
    # and require bootstrapping maturin from a Rust sdist inside PEP 517
    # build isolation, which is the failure mode this formula is escaping.
    python = Formula["python@3.12"].opt_libexec/"bin/python3"
    system python, "-m", "venv", libexec
    system libexec/"bin/pip", "install", "--no-warn-script-location", buildpath

    # dulwich's prebuilt macOS wheel ships a Mach-O accelerator
    # (_diff_tree.cpython-*-darwin.so) with insufficient header
    # padding for Homebrew's post-install pass to rewrite its
    # `install_name` to the absolute Cellar path. Rebuild dulwich
    # from sdist with `PURE=1`, which disables the C accelerator
    # entirely — there's no dylib left to relocate, and dulwich
    # transparently falls back to its pure-Python diff/pack/object
    # implementations (used here only by Pythinker's memory-commit
    # codepath, where perf is non-critical).
    ENV["PURE"] = "1"
    system libexec/"bin/pip", "install", "--force-reinstall",
      "--no-binary=dulwich", "--no-deps", "--no-warn-script-location",
      "dulwich"

    bin.install_symlink libexec/"bin/pythinker"
  end

  test do
    assert_match "2.7.0", shell_output("#{bin}/pythinker --version")
  end
end
