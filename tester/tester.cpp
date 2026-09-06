#include <bits/stdc++.h>
using namespace std;

namespace filesystem = std::filesystem;

string quote_argument(const filesystem::path& path) {
    string text = path.string();
    if (text.find('"') != string::npos) {
        throw invalid_argument("paths containing a quote are unsupported");
    }
    return '"' + text + '"';
}

bool equal_tokens(const filesystem::path& lhs_path,
                  const filesystem::path& rhs_path) {
    ifstream lhs(lhs_path);
    ifstream rhs(rhs_path);
    if (!lhs || !rhs) throw runtime_error("cannot open an output file");

    string lhs_token;
    string rhs_token;
    while (true) {
        bool has_lhs = (bool)(lhs >> lhs_token);
        bool has_rhs = (bool)(rhs >> rhs_token);
        if (has_lhs != has_rhs) return false;
        if (!has_lhs) return true;
        if (lhs_token != rhs_token) return false;
    }
}

int run(const string& command) {
    int exit_code = system(command.c_str());
    if (exit_code != 0) {
        cerr << "Command failed with code " << exit_code << ":\n"
             << command << '\n';
    }
    return exit_code;
}

int main(int argument_count, char** arguments) {
    if (argument_count != 5) {
        cerr << "Usage: tester <generator> <candidate> <reference> <rounds>\n"
             << "The generator receives the current 1-based round as argv[1].\n";
        return 2;
    }

    filesystem::path generator = filesystem::absolute(arguments[1]);
    filesystem::path candidate = filesystem::absolute(arguments[2]);
    filesystem::path reference = filesystem::absolute(arguments[3]);
    int rounds;
    try {
        rounds = stoi(arguments[4]);
    } catch (const exception&) {
        cerr << "rounds must be a positive integer\n";
        return 2;
    }
    if (rounds <= 0) {
        cerr << "rounds must be a positive integer\n";
        return 2;
    }
    for (const filesystem::path& executable :
         {generator, candidate, reference}) {
        if (!filesystem::is_regular_file(executable)) {
            cerr << "Executable does not exist: " << executable << '\n';
            return 2;
        }
    }

    auto timestamp = chrono::steady_clock::now().time_since_epoch().count();
    filesystem::path temporary_directory =
        filesystem::temp_directory_path() /
        ("icpc-stress-" + to_string(timestamp));
    filesystem::create_directory(temporary_directory);
    filesystem::path input = temporary_directory / "input.txt";
    filesystem::path candidate_output =
        temporary_directory / "candidate.txt";
    filesystem::path reference_output =
        temporary_directory / "reference.txt";

    try {
        for (int round = 1; round <= rounds; ++round) {
            string generate_command = quote_argument(generator) + " " +
                to_string(round) + " > " + quote_argument(input);
            string candidate_command = quote_argument(candidate) + " < " +
                quote_argument(input) + " > " + quote_argument(candidate_output);
            string reference_command = quote_argument(reference) + " < " +
                quote_argument(input) + " > " + quote_argument(reference_output);
            if (run(generate_command) != 0 || run(candidate_command) != 0 ||
                run(reference_command) != 0) {
                cerr << "Artifacts kept in " << temporary_directory << '\n';
                return 1;
            }
            if (!equal_tokens(candidate_output, reference_output)) {
                cerr << "Mismatch in round " << round << "\n"
                     << "Artifacts kept in " << temporary_directory << '\n';
                return 1;
            }
            if (round % 100 == 0 || round == rounds) {
                cerr << "Passed " << round << '/' << rounds << " rounds\r";
            }
        }
        cerr << '\n';
        filesystem::remove_all(temporary_directory);
    } catch (const exception& error) {
        cerr << "Tester error: " << error.what() << '\n'
             << "Artifacts kept in " << temporary_directory << '\n';
        return 1;
    }
    return 0;
}
